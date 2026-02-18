//
//  UpcomingDates.swift
//  Edmund
//
//  Created by Hollan Sellars on 2/14/26.
//

import SwiftUI
import CoreData
import os

/// Stores information about the due date of a specific bill.
public enum BillDueDateInfo : Equatable, Sendable {
    /// Indicates that the bill has no next due date because it has expired.
    case expired
    /// The next due date (relative to the computation time) that the bill comes due next.
    case dueOn(Date)
    
    /// Obtains all due dates for all bills using a background task & context.
    /// - Parameters:
    ///     - using: The container to fetch data from.
    ///     - calendar: The calendar to use for selecting dates.
    ///     - taskPriority: The priority to pass to the background task.
    /// - Throws: Any error that ``getAllDueDates(cx:calendar:)`` throws. Specifically, if the fetch fails, it will throw.
    /// - Returns: A sendable dictionary with the bill's Object ID and their specified due date.
    public static func getAllDueDates(using: NSPersistentContainer, calendar: Calendar, taskPriority: TaskPriority = .userInitiated) async throws -> [NSManagedObjectID : BillDueDateInfo] {
        return try await Task(priority: taskPriority) {
            return try BillDueDateInfo.getAllDueDates(cx: using.newBackgroundContext(), calendar: calendar)
        }.value;
    }
    /// Obtains all due dates for all bills using a specified context.
    /// - Parameters:
    ///     - cx: The object contex to fetch the bills from.
    ///     - calendar: The calendar to compute dates from.
    ///
    /// - Throws: Any error occured while fetching Bill isntances.
    /// - Warning: This will block the current thread and compute all due dates. Do not use this on the main thread. Use ``getAllDueDates(using:calendar:taskPriority:)`` instead.
    public static func getAllDueDates(cx: NSManagedObjectContext, calendar: Calendar) throws -> [NSManagedObjectID : BillDueDateInfo] {
        var result: [NSManagedObjectID : BillDueDateInfo] = [:];
        
        let billsRequest = Bill.fetchRequest();
        let bills = try cx.fetch(billsRequest);
        
        for bill in bills {
            if let date = bill.nextDueDate(calendar: calendar) {
                result[bill.objectID] = .dueOn(date)
            }
            else {
                result[bill.objectID] = .expired
            }
        }
        
        return result;
    }
}

/// The state of bill due date computation.
/// This is used to indicate to the UI how to present date data.
public enum DueDatesComputationState : Sendable, Equatable {
    /// The system is currently computing results.
    case loading
    /// The system failed to compute results.
    case error
    /// The system has completed computing results.
    case loaded( [NSManagedObjectID : BillDueDateInfo] )
}

/// A simple structure used to indicate an error for diff updating.
fileprivate struct UpdateError : Error { }

/// The UI presentable & isolated data for bill due dates.
@MainActor
fileprivate final class BillsDateUIData : Sendable {
    init() {
        self.state = .loading;
    }
    
    /// The current state of the computation.
    var state: DueDatesComputationState;
    
    /// Returns the dates if computed, or an empty dictionary if loading or error state.
    func getCurrentDates() -> [NSManagedObjectID : BillDueDateInfo] {
        switch self.state {
            case .error:
                fallthrough
            case .loading:
                return [:];
            case .loaded(let v):
                return v;
        }
    }
    
    /// Sets the state to loading.
    func reset() {
        withAnimation {
            self.state = .loading;
        }
    }
    /// Sets the state to error.
    func withError() {
        withAnimation {
            self.state = .error
        }
    }
    /// Sets the state to loaded with a specified data bundle.
    func withValue(_ data: [NSManagedObjectID : BillDueDateInfo] ) {
        withAnimation {
            self.state = .loaded(data)
        }
    }
    
    /// Indicates that the system is in an error state.
    var hasError: Bool {
        self.state == .error
    }
    /// Indicates that the system is in the loaded state.
    var isLoaded: Bool {
        switch self.state {
            case .loading:
                fallthrough
            case .error:
                return false;
            case .loaded(_):
                return true;
        }
    }
    /// Indicates that the system is in the loading state.
    var isLoading: Bool {
        self.state == .loading
    }
    /// If loaded, returns the specified due date for a bill, providing such a bill has been computed.
    func fetchAgainst(id: NSManagedObjectID) -> BillDueDateInfo? {
        switch self.state {
            case .loading:
                fallthrough
            case .error:
                return nil
            case .loaded(let values):
                return values[id]
        }
    }
}
fileprivate final actor BillsDueDateActor {
    init(cx: NSManagedObjectContext, log: LoggerSystem, calendar: Calendar, data: BillsDateUIData) {
        self.innerCx = cx;
        self.log = log;
        self.calendar = calendar;
        self.data = data;
    }
    
    private let innerCx: NSManagedObjectContext;
    private let log: LoggerSystem;
    private let calendar: Calendar;
    private let data: BillsDateUIData;
    
    func diffDueDates(update: [NSManagedObjectID], delete: [NSManagedObjectID]) async {
        var dueDates = await data.getCurrentDates();
        
        let (log, calendar) = (self.log, self.calendar); //Remove closure capture from self
        
        for id in delete {
            dueDates.removeValue(forKey: id);
        }
        
        for id in update {
            do {
                let newDate: BillDueDateInfo = try await innerCx.perform { [innerCx] in
                    guard let target = innerCx.object(with: id) as? Bill else {
                        log.app.error("Attempted to fetch object with ID \(id) as a Bill, but it is another type.");
                        throw UpdateError();
                    }
                    
                    if let dueDate = target.nextDueDate(calendar: calendar) {
                        return .dueOn(dueDate)
                    }
                    else {
                        return .expired
                    }
                };
                
                dueDates[id] = newDate;
            }
            catch {
                log.data.warning("Unable to fetch all new bill due dates.");
                
                await data.withError()
            }
        }
        
        log.data.info("Completed update of bill due dates.")
        
        //Now that we removed the deleted, and updated the new/updated instances, we can update the main state.
        await data.withValue(dueDates)
    }
    
    func reset() async {
        do {
            await data.reset();
            
            log.data.debug("Determining bill due dates.");
            
            let result = try await BillDueDateInfo.getAllDueDates(
                using: DataStack.shared.currentContainer,
                calendar: calendar,
                taskPriority: Task.currentPriority
            );
            
            log.data.debug("Bill due dates determined.");
            
            await data.withValue(result);
        }
        catch let e {
            log.data.error("Unable to fetch the bill due dates, error: \(e)");
            await data.withError();
        }
    }
    
    func fetchAgainst(id: NSManagedObjectID) async -> BillDueDateInfo? {
        await self.data.fetchAgainst(id: id)
    }
}

@Observable
public final class BillsDateManager : Sendable {
    @MainActor
    public init(using: NSPersistentContainer = DataStack.shared.currentContainer, calendar: Calendar, log: LoggerSystem) {
        let ui = BillsDateUIData();
        
        let cx = using.viewContext;
        let backgroundCx = using.newBackgroundContext();
        
        self.log = log;
        self.ui = ui;
        self.actor = .init(cx: backgroundCx, log: log, calendar: calendar, data: ui)
        
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: cx,
            queue: nil
        ) { [weak self] note in
            self?.handleSave(note: note)
        };
    }
    
    private let log: LoggerSystem;
    private let actor: BillsDueDateActor;
    private let ui: BillsDateUIData;

    @MainActor
    public var hasError: Bool {
        ui.hasError
    }
    @MainActor
    public var isLoaded: Bool {
        ui.isLoaded
    }
    @MainActor
    public var isLoading: Bool {
        ui.isLoading
    }
    @MainActor
    public func fetchAgainst(id: NSManagedObjectID) -> BillDueDateInfo? {
        ui.fetchAgainst(id: id)
    }
    public nonisolated func fetchAgainstGuarded(id: NSManagedObjectID) async -> BillDueDateInfo? {
        await actor.fetchAgainst(id: id)
    }
    public nonisolated func reset() async {
        await actor.reset();
    }
    
    private nonisolated func handleSave(note: Notification) {
        guard let info = note.userInfo else {
            log.app.warning("Got notification to update bills, but there is no payload in the notification.")
            return;
        }
        
        log.app.info("Got notification to update bill due dates.");
        
        let inserted = (info[NSInsertedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let updated = (info[NSUpdatedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        
        let updatedTargets = inserted.union(updated)
            .filter { $0.entity.name == "Bill" }
            .map { $0.objectID };
        let deletedTargets = deleted
            .filter { $0.entity.name == "Bill" }
            .map { $0.objectID };
        
        log.app.info("Processing \(updatedTargets.count) updated bill(s), and \(deletedTargets.count) deleted bill(s).");
        
        Task {
            await actor.diffDueDates(update: updatedTargets, delete: deletedTargets)
        }
    }
}

@MainActor
fileprivate struct BillsDateManagerKey : EnvironmentKey {
    typealias Value = BillsDateManager;
    static let defaultValue: BillsDateManager = .init(calendar: .current, log: .init())
}

public extension EnvironmentValues {
    @MainActor
    var billsDateManager: BillsDateManager {
        get { self[BillsDateManagerKey.self] }
        set { self[BillsDateManagerKey.self] = newValue }
    }
}

public struct BillDueDateManagerErrorModifier : ViewModifier {
    
    @State private var showingAlert = false;
    @Environment(\.billsDateManager) private var billsDateManager;
    
    public func body(content: Content) -> some View {
        content
            .alert("Bills Error", isPresented: $showingAlert) {
                Button("Ok") { showingAlert = false }
                Button("Reset") {
                    Task {
                        await billsDateManager.reset();
                    }
                }
            } message: {
                Text("Edmund ran into a problem while trying to determine when the bills come due next. Press 'Reset' to try again.")
            }
            .onAppear {
                if billsDateManager.hasError {
                    self.showingAlert = true;
                }
            }
        }
}
public extension View {
    func withBillsDueDateWarning() -> some View {
        self.modifier(BillDueDateManagerErrorModifier())
    }
}

public struct DueDateViewer : View {
    public init(_ bill: Bill) {
        self.forBill = bill.objectID;
    }
    public init(forBill: NSManagedObjectID) {
        self.forBill = forBill;
    }
    
    private let forBill: NSManagedObjectID;
    @Environment(\.billsDateManager) private var billsDateManager;
    
    public var body: some View {
        if let status = billsDateManager.fetchAgainst(id: forBill) {
            switch status {
                case .dueOn(let date): Text(date.formatted(date: .numeric, time: .omitted))
                case .expired: Text("Expired").italic()
            }
        }
        else {
            Text("-")
        }
    }
}

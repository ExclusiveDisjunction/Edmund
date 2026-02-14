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
    case expired
    case dueOn(Date)
    
    public static func getAllDueDates(using: NSPersistentContainer, calendar: Calendar, taskPriority: TaskPriority = .userInitiated) async throws -> [NSManagedObjectID : BillDueDateInfo] {
        return try await Task(priority: taskPriority) {
            return try BillDueDateInfo.getAllDueDates(cx: using.newBackgroundContext(), calendar: calendar)
        }.value;
    }
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

public enum DueDatesComputationState : Sendable, Equatable {
    case loading
    case error
    case loaded( [NSManagedObjectID : BillDueDateInfo] )
}

@Observable
public final class BillsDateManager : Sendable {
    @MainActor
    public init(using: NSPersistentContainer = DataStack.shared.currentContainer, calendar: Calendar, log: LoggerSystem) {
        self.state = .loading;
        
        let cx = using.viewContext;
        self.innerCx = using.newBackgroundContext();
        self.log = log;
        self.calendar = calendar;
        
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: cx,
            queue: nil
        ) { [weak self] note in
            self?.handleSave(note: note)
        };
    }
    
    private let innerCx: NSManagedObjectContext;
    private let log: LoggerSystem?;
    private let calendar: Calendar;
    
    @MainActor
    public var state: DueDatesComputationState;
    
    @MainActor
    public var hasError: Bool {
        self.state == .error
    }
    @MainActor
    public var isLoaded: Bool {
        switch self.state {
            case .loading:
                fallthrough
            case .error:
                return false;
            case .loaded(_):
                return true;
        }
    }
    @MainActor
    public func fetchAgainst(id: NSManagedObjectID) -> BillDueDateInfo? {
        switch self.state {
            case .loading:
                fallthrough
            case .error:
                return nil
            case .loaded(let values):
                return values[id]
        }
    }
    
    private nonisolated func handleSave(note: Notification) {
        guard let info = note.userInfo else {
            log?.app.warning("Got notification to update bills, but there is no payload in the notification.")
            return;
        }
        
        log?.app.info("Got notification to update bill due dates.");
        
        let inserted = (info[NSInsertedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let updated = (info[NSUpdatedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        
        let updatedTargets = inserted.union(updated)
            .filter { $0.entity.name == Bill.className() }
            .map { $0.objectID };
        let deletedTargets = deleted
            .filter { $0.entity.name == Bill.className() }
            .map { $0.objectID };
        
        log?.app.info("Processing \(updatedTargets.count) updated bill(s), and \(deletedTargets.count) deleted bill(s).");
        
        Task {
            await self.diffDueDates(update: updatedTargets, delete: deletedTargets)
        }
    }
    
    private struct UpdateError : Error { }
    
    private nonisolated func diffDueDates(update: [NSManagedObjectID], delete: [NSManagedObjectID]) async {
        var dueDates: [NSManagedObjectID : BillDueDateInfo] = await MainActor.run {
            switch self.state {
                case .error:
                    fallthrough
                case .loading:
                    return [:];
                case .loaded(let v):
                    return v
            }
        };
        
        let (log, calendar) = (self.log, self.calendar); //Remove closure capture from self
        
        for id in delete {
            dueDates.removeValue(forKey: id);
        }
        
        for id in update {
            do {
                let newDate: BillDueDateInfo = try await innerCx.perform { [innerCx] in
                    guard let target = innerCx.object(with: id) as? Bill else {
                        log?.app.error("Attempted to fetch object with ID \(id) as a Bill, but it is another type.");
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
                log?.data.warning("Unable to fetch all new bill due dates.");
                
                await MainActor.run {
                    withAnimation {
                        self.state = .error
                    }
                }
            }
        }
        
        //Now that we removed the deleted, and updated the new/updated instances, we can update the main state.
        await MainActor.run {
            withAnimation {
                self.state = .loaded(dueDates)
            }
        }
    }
    
    public nonisolated func reset() async {
        do {
            await MainActor.run {
                withAnimation {
                    self.state = .loading
                }
            }
            
            log?.data.debug("Determining bill due dates.");
            
            let result = try await BillDueDateInfo.getAllDueDates(
                using: DataStack.shared.currentContainer,
                calendar: calendar,
                taskPriority: Task.currentPriority
            );
            
            log?.data.debug("Bill due dates determined.");
            
            await MainActor.run {
                withAnimation {
                    self.state = .loaded(result)
                }
            }
        }
        catch let e {
            log?.data.error("Unable to fetch the bill due dates, error: \(e)");
            await MainActor.run {
                withAnimation {
                    self.state = .error
                }
            }
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

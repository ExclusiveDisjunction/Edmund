//
//  BillBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

/// An identifier that can be used for any `BillBase`.
public struct BillBaseID : Hashable, Equatable, RawRepresentable, Sendable {
    public init(name: String, company: String, location: String?) {
        self.name = name
        self.company = company
        self.location = location
    }
    public init?(rawValue: String) {
        let split = rawValue.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) };
        guard split.count == 3 else { return nil }
        guard !split[0].isEmpty && !split[1].isEmpty else { return nil } //The last part can be empty
        
        self.name = split[0]
        self.company = split[1]
        self.location = split[2].isEmpty ? nil : split[2]
    }
    
    /// The name of the bill
    public let name: String;
    /// The name of the company the bill comes from
    public let company: String;
    /// An optional location where that bill origionates. Think an electric bill.
    public let location: String?;
    public var rawValue: String {
        "\(name).\(company).\(location ?? String())"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(company)
        hasher.combine(location)
    }
    public static func ==(lhs: BillBaseID, rhs: BillBaseID) -> Bool {
        lhs.name == rhs.name && lhs.company == rhs.company && lhs.location == rhs.location
    }
}

/// A protocol that allows for the enforcement of basic properties that are shared between `Bill` and `Utility` classes.
public protocol BillBase : Identifiable<UUID>, UniqueElement, NamedElement, AnyObject, PersistentModel where Self.UID == BillBaseID {
    associatedtype Datapoint: BillHistoryRecord
    
    /// The start date of the bill. This is used to compute the upcoming dates.
    var startDate: Date { get set }
    /// An optional end date for the bill. By convention, `endDate` should be after `startDate`, if a value is provided.
    var endDate: Date? { get set }
    /// The next due date of the bill
    var nextDueDate: Date? { get }
    /// The bill period. This represent how often it will come due.
    var period: TimePeriods { get set }
    /// The kind of bill.
    var kind: BillsKind { get }
    /// How much the bill costs each time it comes due. This may be an approximation.
    var amount: Decimal { get }
    /// The company that this bill is attached to.
    var company: String { get set }
    /// An optional location used to uniquely identify a bill.
    /// For example, say you have an electric bill for two different apartments, but the same electric company. The bills would be indistiquishable, but this can help separate it.
    var location: String? { get set }
    /// When true, it is known that the bill will automatically be debited to the account.
    var autoPay: Bool { get set }
    var history: [Datapoint] { get set }
}

public struct ResolvedBillHistory : Identifiable, Sendable {
    public init<T>(from: T, date: Date?, id: UUID = UUID()) where T: BillHistoryRecord {
        self.id = id
        self.amount = from.amount
        self.date = date
    }
    
    public let id: UUID;
    public let amount: Decimal?;
    public var date: Date?;
}
@Observable
public class BillHistorySnapshot : Identifiable, Hashable, Equatable {
    public init(date: Date?, id: UUID = UUID()) {
        self.id = id
        self.date = date
        self.amount = .init()
        self.skipped = false
    }
    public init<T>(from: T, date: Date?, id: UUID = UUID()) where T: BillHistoryRecord {
        self.id = id
        self.date = date
        if let value = from.amount {
            self.skipped = false
            self.amount = .init(rawValue: value)
        }
        else {
            self.skipped = true
            self.amount = .init()
        }
    }
    
    public let id: UUID;
    public var skipped: Bool;
    public var amount: CurrencyValue;
    public var date: Date?;
    
    public var trueAmount: CurrencyValue? {
        get {
            skipped ? nil : amount
        }
        set {
            if let value = newValue {
                self.skipped = false
                self.amount = value
            }
            else {
                self.skipped = true
            }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(skipped)
        hasher.combine(amount)
        hasher.combine(date)
    }
    public static func ==(lhs: BillHistorySnapshot, rhs: BillHistorySnapshot) -> Bool {
        lhs.trueAmount == rhs.trueAmount && lhs.date == rhs.date
    }
}

public extension BillBase {
    func computeNextDueDate(relativeTo: Date = .now) -> Date? {
        var walker = TimePeriodWalker(start: self.startDate, end: self.endDate, period: self.period, calendar: .current)
        return walker.walkToDate(relativeTo: relativeTo)
    }
    /// When true, the `endDate` exists, and it is in the past.
    var isExpired: Bool {
        if let endDate = endDate {
            Date.now > endDate
        }
        else {
            false
        }
    }
    /// Returns the price per some other time period.
    func pricePer(_ period: TimePeriods) -> Decimal {
        self.amount * self.period.conversionFactor(period)
    }
    
    static func updateLists<S1, S2>(oldList: S1, newList: S2, offset: Int = 0) where S1: Sequence, S1.Element == Self.Datapoint, S2: Sequence, S2.Element == BillHistorySnapshot {
        for (old, new) in zip(oldList, newList.enumerated()) {
            old.id = new.offset + offset
            old.amount = new.element.amount.rawValue
        }
    }
    
    @MainActor
    func updateFromBase(snap: BillBaseSnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        let name = snap.name.trimmingCharacters(in: .whitespaces)
        let company = snap.company.trimmingCharacters(in: .whitespaces)
        let location = snap.location.trimmingCharacters(in: .whitespaces)
        let id = BillBaseID(name: name, company: company, location: snap.hasLocation ? location : nil)
        
        if id != self.uID {
            guard await unique.swapId(key: .init((any BillBase).self), oldId: self.uID, newId: id) else {
                throw UniqueFailureError(value: id)
            }
        }
        
        self.name = name
        self.company = company
        self.location = snap.hasLocation ? location : nil
        self.startDate = snap.startDate
        self.endDate = snap.hasEndDate ? snap.endDate : nil
        self.period = snap.period
        self.autoPay = snap.autoPay
        
        let oldPoints = self.history;
        let newPoints = snap.history;
        
        // The point here is to use as many old instances as possible, while integrating the changes from the incoming elements.
        // The order is taken from the snapshot, so the same amounts in order will be placed back into the utility.
        
        if newPoints.count == oldPoints.count {
            Self.updateLists(oldList: oldPoints, newList: newPoints)
        }
        else if newPoints.count > oldPoints.count {
            //First, update the elements in the first array, and then create new elements. Join the two lists after adding the newly created.
            let matchedPoints = newPoints[0..<oldPoints.count];
            Self.updateLists(oldList: oldPoints, newList: matchedPoints)
            
            let newInstances = newPoints[oldPoints.count...].enumerated().map { Self.Datapoint($0.element.amount.rawValue, index: $0.offset + oldPoints.count ) };
            
            for instance in newInstances {
                self.modelContext?.insert(instance)
            }
            
            let allPoints = oldPoints + newInstances;
            self.history = allPoints;
        }
        else { //less
            // First grab the instances from the old points that match the count, and then remove the other instances.
            let keeping = Array(oldPoints[..<newPoints.count]); //Being stored back so we need it in array format
            let deleting = oldPoints[newPoints.count...];
            
            Self.updateLists(oldList: keeping, newList: newPoints)
            self.history = keeping;
            
            for delete in deleting {
                self.modelContext?.delete(delete)
            }
        }
    }
    
    @MainActor
    func addPoint(amount: Decimal?) {
        let max = (self.history.map { $0.id }.max() ?? 0) + 1;
        let new = Self.Datapoint(amount, index: max);
        self.history.append(new);
        self.modelContext?.insert(new);
    }
}

/// Since SwiftUI does not allow direct access of `any BillBase`, this will allow for defined, identifable access.
/// Use this structure to store `any BillBase`, allowing for selection, inspection, and abstract deleting.
public struct BillBaseWrapper : Identifiable, Queryable {
    public typealias SortType = BillsSort
    public typealias FilterType = BillsKind
    
    /// Creates the instance around some `BillBase` instance.
    public init(_ data: any BillBase, id: UUID = UUID()) {
        self.data = data
        self.id = id
    }
    
    /// The held data
    public var data: any BillBase;
    public var id: UUID;
    
    public static func sort(_ data: [BillBaseWrapper], using: BillsSort, order: SortOrder) -> [BillBaseWrapper] {
        switch using {
            case .amount: data.sorted(using: KeyPathComparator(\.data.amount, order: order))
            case .kind:   data.sorted(using: KeyPathComparator(\.data.kind,   order: order))
            case .name:   data.sorted(using: KeyPathComparator(\.data.name,   order: order))
        }
    }
    public static func filter(_ data: [BillBaseWrapper], using: Set<BillsKind>) -> [BillBaseWrapper] {
        data.filter { using.contains($0.data.kind) }
    }
    
    /// A complete list of bill examples, from `Bill` and `Utility`.
    @MainActor
    public static let exampleBills: [BillBaseWrapper] = Bill.exampleBills.map { .init($0) } + Utility.exampleUtility.map { .init($0) }
}

/// The snapshot for `any BillBase`. This is used inside `BillSnapshot` and `UtilitySnapshot` to simplify the process.
@Observable
public class BillBaseSnapshot: Hashable, Equatable {
    public init() {
        self.oldId = .init(name: "", company: "", location: nil)
        self.name = ""
        self.startDate = .now
        self.hasEndDate = false
        self.endDate = .now
        self.period = .monthly
        self.company = ""
        self.hasLocation = false
        self.location = ""
        self.autoPay = true
        self.history = [];
    }
    /// Constructs a snapshot around an instance of a `BillBase`.
    public init<T>(_ from: T) where T: BillBase {
        self.name = from.name
        self.startDate = from.startDate
        self.hasEndDate = from.endDate != nil
        self.endDate = from.endDate ?? Date.now
        self.period = from.period
        self.company = from.company
        self.hasLocation = from.location != nil
        self.location = from.location ?? String()
        self.autoPay = from.autoPay;
        self.oldId = from.uID;
        
        var walker = TimePeriodWalker(start: from.startDate, end: from.endDate, period: from.period, calendar: .current)
        
        self.history = from.history.map { BillHistorySnapshot(from: $0, date: walker.step())}
    }
    
    @ObservationIgnored private var oldId: BillBaseID;
    
    /// The name of the bill
    public var name: String;
    /// The bill's start date
    public var startDate: Date;
    /// When true, the snapshot will fill the `endDate` property to the `self.endDate` value. However, if false, `endDate` will be `nil`.
    public var hasEndDate: Bool;
    /// The bill's end date
    public var endDate: Date;
    /// The bill's period
    public var period: TimePeriods;
    /// The company the bill is with
    public var company: String;
    /// When true, the snapshot will fill the `location` property to the `self.location` value. However, if false, `location` will be `nil`. 
    public var hasLocation: Bool;
    /// The location of the bill (like apartment)
    public var location: String;
    /// If the bill has autopay setup or not
    public var autoPay: Bool;
    public var history: [BillHistorySnapshot];
    
    /// Validates the bill with its current information.
    @MainActor
    public func validate(unique: UniqueEngine) async -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespaces)
        let company = company.trimmingCharacters(in: .whitespaces)
        let location = location.trimmingCharacters(in: .whitespaces)
        let id = BillBaseID(name: name, company: company, location: hasLocation ? location : nil)
        
        if oldId != id {
            guard await unique.isIdOpen(key: .init((any BillBase).self), id: id) else { return .unique }
        }
        
        guard !name.isEmpty && !company.isEmpty else { return .empty }
        if hasLocation && location.isEmpty { return .empty }
        if hasEndDate && endDate < startDate { return .invalidInput }
        
        for child in self.history {
            if !child.skipped {
                guard child.amount >= 0 else {
                    return .negativeAmount
                }
            }
        }
        
        return nil;
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
        hasher.combine(company)
        hasher.combine(location)
        hasher.combine(autoPay)
        hasher.combine(history)
    }
    public static func ==(lhs: BillBaseSnapshot, rhs: BillBaseSnapshot) -> Bool {
        guard lhs.name == rhs.name && lhs.startDate == rhs.startDate && lhs.hasEndDate == rhs.hasEndDate && lhs.period == rhs.period && lhs.company == rhs.company && lhs.hasLocation == rhs.hasLocation && lhs.autoPay == rhs.autoPay && lhs.history == rhs.history else { return false }
        
        if lhs.hasLocation && lhs.location != rhs.location { return false }
        if lhs.hasEndDate && lhs.endDate != rhs.endDate { return false }
        
        return true
    }
}

//
//  Bill.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI
import SwiftData
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

extension Bill : UniqueElement {
    public static let objId: ObjectIdentifier = .init(Bill.self)
    public var uID: BillBaseID {
        .init(name: name, company: company, location: location)
    }
}
extension Bill : NamedElement { }
extension Bill : SnapshotableElement {
    public typealias Snapshot = BillSnapshot
    
    static func updateLists<S1, S2>(oldList: S1, newList: S2, offset: Int = 0) where S1: Sequence, S1.Element == BillDatapoint, S2: Sequence, S2.Element == BillHistorySnapshot {
        for (old, new) in zip(oldList, newList.enumerated()) {
            old.id = new.offset + offset
            old.amount = new.element.amount.rawValue
        }
    }
    
    public func makeSnapshot() -> BillSnapshot {
        BillSnapshot(self)
    }
    public static func makeBlankSnapshot() -> BillSnapshot {
        BillSnapshot()
    }
    public func update(_ from: BillSnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        let name = from.name.trimmingCharacters(in: .whitespaces)
        let company = from.company.trimmingCharacters(in: .whitespaces)
        let location = from.location.trimmingCharacters(in: .whitespaces)
        let id = BillBaseID(name: name, company: company, location: from.hasLocation ? location : nil)
        
        if id != self.uID {
            guard await unique.swapId(key: .init(Bill.self), oldId: self.uID, newId: id) else {
                throw UniqueFailureError(value: id)
            }
        }
        
        let oldPoints = self.history;
        let newPoints = from.history;
        
        // The point here is to use as many old instances as possible, while integrating the changes from the incoming elements.
        // The order is taken from the snapshot, so the same amounts in order will be placed back into the utility.
        
        if newPoints.count == oldPoints.count {
            Self.updateLists(oldList: oldPoints, newList: newPoints)
        }
        else if newPoints.count > oldPoints.count {
            //First, update the elements in the first array, and then create new elements. Join the two lists after adding the newly created.
            let matchedPoints = newPoints[0..<oldPoints.count];
            Self.updateLists(oldList: oldPoints, newList: matchedPoints)
            
            let newInstances = newPoints[oldPoints.count...].enumerated().map { BillDatapoint($0.element.amount.rawValue, index: $0.offset + oldPoints.count, parent: self) };
            
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
        
        self.name = name
        self.company = company
        self.location = from.hasLocation ? location : nil
        self.startDate = from.startDate
        self.endDate = from.hasEndDate ? from.endDate : nil
        self.period = from.period
        self.autoPay = from.autoPay
        self._amount   = from.amount.rawValue
        self.kind = from.kind
    }
}
extension Bill : InspectableElement {
    public func makeInspectView() -> BillInspect {
        BillInspect(self)
    }
}
extension Bill : EditableElement {
    public static func makeEditView(_ snap: BillSnapshot) -> BillEdit {
        BillEdit(snap)
    }
}
extension Bill : TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Bill",
            plural:   "Bills",
            inspect:  "Inspect Bill",
            edit:     "Edit Bill",
            add:      "Add Bill"
        )
    }
}
extension Bill : Queryable {
    public static func sort(_ data: [Bill], using: BillsSort, order: SortOrder) -> [Bill] {
        switch using {
            case .amount: data.sorted(using: KeyPathComparator(\.amount, order: order))
            case .kind:   data.sorted(using: KeyPathComparator(\.kind,   order: order))
            case .name:   data.sorted(using: KeyPathComparator(\.name,   order: order))
        }
    }
    public static func filter(_ data: [Bill], using: Set<BillsKind>) -> [Bill] {
        data.filter { using.contains($0.kind) }
    }
}

// Constructors
public extension Bill {
    /// Creates the bill based on a specific kind.
    convenience init(kind: BillsKind) {
        self.init(name: "", kind: kind, amount: 0, company: "", location: nil, start: .now, end: nil, period: .monthly)
    }
    /// Creates a subscription kind bill, with specified values.
    convenience init(sub: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.init(name: sub, kind: .subscription,  amount: amount, company: company, location: location, start: start, end: end, period: period)
    }
    /// Creates a bill kind, with specified values
    convenience init(bill: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.init(name: bill, kind: .bill, amount: amount, company: company, location: location, start: start, end: end, period: period)
    }
}

// Amounts
public extension Bill {
    func historyAverage() -> Decimal {
        let newHash = self.history.hashValue;
        if self._historyHash == newHash {
            return self._historyAverage;
        }
        
        var total: Decimal = 0;
        var count: Decimal = 0;
        self.history.forEach { elem in
            guard let amount = elem.amount else {
                return
            }
            
            total += amount;
            count += 1;
        }
        
        let avg = total / count;
        self._historyAverage = avg;
        self._historyHash = newHash;
        
        return avg;
    }
    
    var amount: Decimal {
        get {
            if self.kind == .utility {
                self.historyAverage()
            }
            else {
                self._amount
            }
        }
        set {
            self._amount = newValue
        }
    }
    
    
    /// Returns the price per some other time period.
    func pricePer(_ period: TimePeriods) -> Decimal {
        self.amount * self.period.conversionFactor(period)
    }
    
    @MainActor
    func addPoint(amount: Decimal?) {
        let max = (self.history.map { $0.id }.max() ?? 0) + 1;
        let new = BillDatapoint(amount, index: max, parent: self);
        self.history.append(new);
        self.modelContext?.insert(new);
    }
}

//Dates
public extension Bill {
    var nextDueDate: Date? {
        var hasher = Hasher()
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
        let computedHash = hasher.finalize()
        let lastHash = _oldHash
        
        _oldHash = computedHash
        
        if let nextDueDate = _nextDueDate, computedHash == lastHash {
            return nextDueDate
        }
        else {
            let result = self.computeNextDueDate()
            _nextDueDate = result;
            return result;
        }
    }
    
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
}

// Examples
public extension Bill {
    /// A list of filler data for bills that have already expired.
    @MainActor
    static var exampleExpiredBills: [Bill] { [
        .init(sub: "Bitwarden Premium",      amount: 9.99,  company: "Bitwarden", start: Date.fromParts(2024, 6, 6)!,  end: Date.fromParts(2025, 3, 1)!, period: .anually),
        .init(sub: "Spotify Premium Family", amount: 16.99, company: "Spotify",   start: Date.fromParts(2020, 1, 17)!, end: Date.fromParts(2025, 3, 2)!, period: .monthly)
    ]
    }
    /// Examples of subscriptions that can be used on the UI.
    @MainActor
    static var exampleSubscriptions: [Bill] { [
        .init(sub: "Apple Music",     amount: 5.99, company: "Apple",   start: Date.fromParts(2025, 3, 2)!,  end: nil),
        .init(sub: "iCloud+",         amount: 2.99, company: "Apple",   start: Date.fromParts(2025, 5, 15)!, end: nil),
        .init(sub: "YouTube Premium", amount: 9.99, company: "YouTube", start: Date.fromParts(2024, 11, 7)!, end: nil)
    ]
    }
    /// Examples of bill kind bills that can be used on UI.
    @MainActor
    static var exampleActualBills: [Bill] { [
        .init(bill: "Student Loan",  amount: 56,  company: "FAFSA",       start: Date.fromParts(2025, 3, 2)!,  end: nil),
        .init(bill: "Car Insurance", amount: 899, company: "The General", start: Date.fromParts(2024, 7, 25)!, end: nil, period: .semiAnually),
        .init(bill: "Internet",      amount: 60,  company: "Spectrum",    start: Date.fromParts(2024, 7, 25)!, end: nil)
    ]
    }
    
    /// A collection of all bills used to show filler UI data.
    @MainActor
    static var exampleBills: [Bill] {
        exampleExpiredBills + exampleSubscriptions + exampleActualBills
    }
}

/// The snapshot type for `Bill`.
@Observable
public final class BillSnapshot : ElementSnapshot {
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
        self.amount = .init()
        self.kind = .bill
    }
    public init(_ from: Bill) {
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
        self.amount = .init(rawValue: from.amount)
        self.kind = from.kind
        
        var walker = TimePeriodWalker(start: from.startDate, end: from.endDate, period: from.period, calendar: .current)
        
        self.history = from.history.map { BillHistorySnapshot(from: $0, date: walker.step())}
    }
    
    @ObservationIgnored private let oldId: BillBaseID;
    
    /// The cost of the bill/subscription
    public var amount: CurrencyValue;
    /// The bill's kind.
    public var kind: BillsKind;
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

    
    public func validate(unique: UniqueEngine) async -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespaces)
        let company = company.trimmingCharacters(in: .whitespaces)
        let location = location.trimmingCharacters(in: .whitespaces)
        let id = BillBaseID(name: name, company: company, location: hasLocation ? location : nil)
        
        if oldId != id {
            guard await unique.isIdOpen(key: Bill.objId, id: id) else { return .unique }
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
        
        if amount.rawValue < 0 { return .negativeAmount }
        
        return nil
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
        hasher.combine(amount)
        hasher.combine(kind)
    }
    
    public static func ==(lhs: BillSnapshot, rhs: BillSnapshot) -> Bool {
        lhs.amount == rhs.amount &&
        lhs.kind == rhs.kind &&
        lhs.name == rhs.name &&
        lhs.startDate == rhs.startDate &&
        (lhs.hasEndDate ? lhs.endDate: nil) == (rhs.hasEndDate ? rhs.endDate : nil) &&
        lhs.period == rhs.period &&
        lhs.company == rhs.company &&
        (lhs.hasLocation ? lhs.location : nil) == (rhs.hasLocation ? rhs.location : nil) &&
        lhs.autoPay == rhs.autoPay &&
        lhs.kind == rhs.kind &&
        lhs.history == rhs.history
    }
}

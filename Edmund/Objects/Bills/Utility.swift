//
//  Utilities.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;
import Foundation;

/// Represents a variable-cost bill
@Model
public final class Utility: BillBase, NamedInspectableElement, NamedEditableElement, UniqueElement {
    public typealias InspectorView = UtilityInspect
    public typealias EditView = UtilityEdit
    public typealias Snapshot = UtilitySnapshot
    
    /// Creates the utility with blank values.
    public convenience init() {
        self.init("", amounts: [], company: "", start: Date.now)
    }
    /// Creates the utility with all fields
    public init(_ name: String, amounts: [UtilityEntry], company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.name = name
        self.startDate = start
        self.endDate = end
        self.rawPeriod = period.rawValue
        self.children = amounts
        self.company = company
        self.location = location
    }
    
    public var id: BillBaseID {
        .init(name: name, company: company, location: location)
    }
    public var name: String = "";
    public var startDate: Date = Date.now;
    public var endDate: Date? = nil;
    public var company: String = "";
    public var location: String? = nil;
    public var notes: String = "";
    public var destination: SubAccount? = nil;
    public var autoPay: Bool = true;
    
    /// The period as a raw value
    private var rawPeriod: Int = 0;
    /// The associated instances of being charged for this bill
    @Relationship(deleteRule: .cascade, inverse: \UtilityEntry.parent)
    public var children: [UtilityEntry]? = nil;
    
    public var amount: Decimal {
        if let children = children {
            children.count == 0 ? Decimal() : children.reduce(0.0, { $0 + $1.amount } ) / Decimal(children.count)
        }
        else {
            Decimal.nan
        }
    }
    public var kind: BillsKind {
        .utility
    }
    public var period: TimePeriods {
        get { TimePeriods(rawValue: rawPeriod)! }
        set { rawPeriod = newValue.rawValue }
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Utility",
            plural:   "Utilities",
            inspect:  "Inspect Utility",
            edit:     "Edit Utility",
            add:      "Add Utility"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Name"), .init(name: "Company"), .init(name: "Location", optional: true) ]
    }
    public func removeFromEngine(unique: UniqueEngine) -> Bool {
        unique.bill(id: self.id, action: .remove)
    }
    
    /// Example utilities that can be used to show UI filler.
    public static let exampleUtility: [Utility] = {
        [
            .init(
                "Gas",
                amounts: [
                    .init(Date.fromParts(2025, 1, 25)!, 25),
                    .init(Date.fromParts(2025, 2, 25)!, 23),
                    .init(Date.fromParts(2025, 3, 25)!, 28),
                    .init(Date.fromParts(2025, 4, 25)!, 27)],
                company: "TECO",
                location: "The Retreat",
                start: Date.fromParts(2025, 1, 25)!,
                end: nil
            ),
            .init(
                "Electric",
                amounts: [
                    .init(Date.fromParts(2025, 1, 17)!, 30),
                    .init(Date.fromParts(2025, 2, 17)!, 31),
                    .init(Date.fromParts(2025, 3, 17)!, 35),
                    .init(Date.fromParts(2025, 4, 17)!, 32)],
                company: "Lakeland Eletric",
                location: "The Retreat",
                start: Date.fromParts(2025, 1, 17)!,
                end: nil
            ),
            .init(
                "Water",
                amounts: [
                    .init(Date.fromParts(2025, 1, 2)!, 10),
                    .init(Date.fromParts(2025, 2, 2)!, 12),
                    .init(Date.fromParts(2025, 3, 2)!, 14),
                    .init(Date.fromParts(2025, 4, 2)!, 15)],
                company: "The Retreat",
                location: "The Retreat",
                start: Date.fromParts(2025, 1, 25)!,
                end: nil
            )
        ]
    }()
}

/// A specific charged instance of a utility's costs.
@Model
public final class UtilityEntry: Identifiable, Hashable, Equatable {
    public init(_ date: Date, _ amount: Decimal, id: UUID = UUID()) {
        self.date = date
        self.amount = amount
        self.id = id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(amount)
    }
    public static func ==(lhs: UtilityEntry, rhs: UtilityEntry) -> Bool {
        lhs.date == rhs.date && lhs.amount == rhs.amount
    }
    
    public var id: UUID = UUID()
    /// The date that the charge occured on
    public var date: Date = Date.now;
    /// How much the bill cost
    public var amount: Decimal = 0;
    /// The parent utility that this is associated with
    @Relationship
    public var parent: Utility? = nil;
}

/// The snapshot for `UtilityEntry`
@Observable
public class UtilityEntrySnapshot: Identifiable, Hashable, Equatable {
    /// Creates a blank instance of a snapshot.
    public convenience init() {
        self.init(amount: 0, date: .now)
    }
    /// Fills in data from a `UtilityEntry`
    public convenience init(_ from: UtilityEntry) {
        self.init(amount: from.amount, date: from.date)
    }
    /// Constructs this instance around specific values.
    public init(amount: Decimal, date: Date, id: UUID = UUID()) {
        self.id = id
        self.amount = .init(rawValue: amount)
        self.date = date
    }
    
    public var id: UUID;
    /// The associated amount
    public var amount: CurrencyValue;
    /// The date this occured on
    public var date: Date;
    
    /// If the amount is valid
    public var isValid: Bool {
        amount >= 0
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
    }
    public static func ==(lhs: UtilityEntrySnapshot, rhs: UtilityEntrySnapshot) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}

/// The snapshot class used for `Utility`.
@Observable
public final class UtilitySnapshot : BillBaseSnapshot, ElementSnapshot {
    public init(_ from: Utility) {
        self.children = from.children?.map { UtilityEntrySnapshot($0) } ?? []
        
        super.init(from)
    }
    
    /// The associated children to this instance
    public var children: [UtilityEntrySnapshot];
    
    /// The total amount that this utility snapshot contains, based on `children`.
    public var amount: Decimal {
        if children.isEmpty {
            return Decimal()
        }
        else {
            return children.reduce(Decimal(), { $0 + $1.amount.rawValue } ) / Decimal(children.count)
        }
    }
    
    public override func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var topResult = super.validate(unique: unique);
        
        if !children.allSatisfy({ $0.isValid} ) { topResult.append(.negativeAmount("Entries")) }
        
        return topResult
    }
    
    public func apply(_ to: Utility, context: ModelContext, unique: UniqueEngine) throws (UniqueFailueError<BillBaseID>) {
        try super.apply(to: to, unique: unique)
        
        if to.children.hashValue != children.hashValue {
            guard let oldChildren = to.children else { return ;}
            for child in oldChildren {
                context.delete(child)
            }
            
            let children = children.map { UtilityEntry($0.date, $0.amount.rawValue) }
            for child in children {
                context.insert(child)
            }
            to.children = children
        }
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(children)
        
        super.hash(into: &hasher)
    }
    public static func ==(lhs: UtilitySnapshot, rhs: UtilitySnapshot) -> Bool {
        (lhs as BillBaseSnapshot) == (rhs as BillBaseSnapshot) && lhs.children == rhs.children
    }
}

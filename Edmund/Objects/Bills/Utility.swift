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
    
    public func makeSnapshot() -> UtilitySnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> UtilitySnapshot {
        .init()
    }
    public func update(_ from: UtilitySnapshot, unique: UniqueEngine) throws(UniqueFailueError<BillBaseID>) {
        try self.updateFromBase(snap: from, unique: unique)
        
        let old = Dictionary(uniqueKeysWithValues: self.children?.map { ($0.id, ChildUpdateRecord($0) ) } ?? [] )
        var new: [UtilityEntry] = [];
        
        for newChild in from.children {
            // Since the UtilitySnapshot never throws, this will also never throw
            try! ChildUpdateRecord.updateOrInsert(newChild, old: old, modelContext: modelContext, unique: unique, list: &new)
        }
        
        let notUpdated = old.values.filter { !$0.visisted }
        for item in notUpdated {
            modelContext?.delete(item.data)
        }
        
        self.children = new;
    }
    
    public func makeInspectView() -> UtilityInspect {
        UtilityInspect(self)
    }
    public static func makeEditView(_ snap: UtilitySnapshot) -> UtilityEdit {
        UtilityEdit(snap)
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

/// The snapshot class used for `Utility`.
@Observable
public final class UtilitySnapshot : BillBaseSnapshot, ElementSnapshot {
    public override init() {
        self.children = []
        
        super.init()
    }
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
        
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(children)
        
        super.hash(into: &hasher)
    }
    public static func ==(lhs: UtilitySnapshot, rhs: UtilitySnapshot) -> Bool {
        (lhs as BillBaseSnapshot) == (rhs as BillBaseSnapshot) && lhs.children == rhs.children
    }
}

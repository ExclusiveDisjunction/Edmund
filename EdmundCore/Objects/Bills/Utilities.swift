//
//  Utilities.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;
import Foundation;

@Model
public final class Utility: BillBase, NamedInspectableElement, NamedEditableElement, UniqueElement {
    public typealias InspectorView = UtilityInspect
    public typealias EditView = UtilityEdit
    public typealias Snapshot = UtilitySnapshot
    
    public convenience init() {
        self.init("", amounts: [], company: "", start: Date.now)
    }
    public init(_ name: String, amounts: [UtilityEntry], company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.name = name
        self.startDate = start
        self.endDate = end
        self.rawPeriod = period.rawValue
        self.children = amounts
        self.company = company
        self.location = location
    }
    
    public var id: String {
        "\(name).\(company).\(location ?? "")"
    }
    public var name: String = "";
    public var startDate: Date = Date.now;
    public var endDate: Date? = nil;
    public var company: String = "";
    public var location: String? = nil;
    public var notes: String = "";
    public var destination: SubAccount? = nil;
    public var autoPay: Bool = true;
    
    private var rawPeriod: Int = 0;
    @Relationship(deleteRule: .cascade, inverse: \UtilityEntry.parent) public var children: [UtilityEntry]? = nil;
    
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
    public var date: Date = Date.now;
    public var amount: Decimal = 0;
    @Relationship public var parent: Utility? = nil;
}

@Observable
public class UtilityEntrySnapshot: Identifiable, Hashable, Equatable {
    public init(_ from: UtilityEntry) {
        self.amount = .init(rawValue: from.amount)
        self.date = from.date
        self.id = UUID()
    }
    public init(amount: Decimal, date: Date, id: UUID = UUID()) {
        self.id = id
        self.amount = .init(rawValue: amount)
        self.date = date
    }
    public init() {
        self.id = UUID()
        self.amount = .init(rawValue: 0.0)
        self.date = Date.now
    }
    
    public var id: UUID;
    public var amount: CurrencyValue;
    public var date: Date;
    public var isSelected: Bool = false;
    
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

@Observable
public final class UtilitySnapshot : BillBaseSnapshotKind {
    public init(_ from: Utility) {
        self.id = UUID()
        self.base = .init(from)
        self.children = from.children?.map { UtilityEntrySnapshot($0) } ?? []
    }
    
    public var id: UUID;
    public var base: BillBaseSnapshot;
    public var children: [UtilityEntrySnapshot];
    
    public var amount: Decimal {
        if children.isEmpty {
            return Decimal()
        }
        else {
            return children.reduce(Decimal(), { $0 + $1.amount.rawValue } ) / Decimal(children.count)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(children)
    }
    public static func ==(lhs: UtilitySnapshot, rhs: UtilitySnapshot) -> Bool {
        lhs.base == rhs.base && lhs.children == rhs.children
    }
    
    public func validate() -> Bool {
        let children_result = children.reduce(true, { $0 && $1.isValid } )
        let top_result = self.base.isValid
        
        if !children_result {
            self.base.errors.insert(.children)
        }
        
        return children_result && top_result
    }
    
    public func apply(_ to: Utility, context: ModelContext) {
        base.apply(to)
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
}

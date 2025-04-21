//
//  Utilities.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;
import Foundation;

@Observable
final class UtilitySnapshot : BillBaseSnapshotKind {
    init(_ from: Utility) {
        self.id = UUID()
        self.base = .init(from)
        self.children = from.children.map { UtilityEntrySnapshot($0) }
    }
    
    var id: UUID;
    var base: BillBaseSnapshot;
    var children: [UtilityEntrySnapshot];
    
    var amount: Decimal {
        if children.isEmpty {
            return Decimal()
        }
        else {
            return children.reduce(Decimal(), { $0 + $1.amount } ) / Decimal(children.count)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(children)
    }
    static func ==(lhs: UtilitySnapshot, rhs: UtilitySnapshot) -> Bool {
        lhs.base == rhs.base && lhs.children == rhs.children
    }
    
    func validate() -> Bool {
        let children_result = children.reduce(true, { $0 && $1.isValid } )
        let top_result = self.base.isValid
        
        if !children_result {
            self.base.errors.insert(.children)
        }
        
        return children_result && top_result
    }
    
    func apply(_ to: Utility, context: ModelContext) {
        base.apply(to)
        if to.children.hashValue != children.hashValue {
            let oldChildren = to.children;
            for child in oldChildren {
                context.delete(child)
            }
            
            let children = children.map { UtilityEntry($0.date, $0.amount) }
            for child in children {
                context.insert(child)
            }
            to.children = children
        }
    }
}

@Model
final class Utility: BillBase, InspectableElement, EditableElement {
    typealias InspectorView = UtilityInspect
    typealias EditView = UtilityEdit
    typealias Snapshot = UtilitySnapshot
    
    init(_ name: String, amounts: [UtilityEntry], company: String, location: String? = nil, start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.startDate = start
        self.endDate = end
        self.rawPeriod = period.rawValue
        self.children = amounts
        self.company = company
        self.location = location
    }
    
    var id: UUID
    @Attribute(.unique) public var name: String
    var startDate: Date;
    var endDate: Date?
    var company: String;
    var location: String?;
    var notes: String = String();
    
    private var rawPeriod: Int;
    @Relationship(deleteRule: .cascade, inverse: \UtilityEntry.parent) var children: [UtilityEntry];
    
    var amount: Decimal {
        children.count == 0 ? Decimal() : children.reduce(0.0, { $0 + $1.amount } ) / Decimal(children.count)
    }
    var kind: BillsKind {
        .utility
    }
    var period: BillsPeriod {
        get { BillsPeriod(rawValue: rawPeriod)! }
        set { rawPeriod = newValue.rawValue }
    }
    
#if DEBUG
    static let exampleUtility: [Utility] = {
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
#endif
}

@Model
class UtilityEntry: Identifiable, Hashable, Equatable {
    init(_ date: Date, _ amount: Decimal, id: UUID = UUID()) {
        self.date = date
        self.amount = amount
        self.id = id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(amount)
    }
    static func ==(lhs: UtilityEntry, rhs: UtilityEntry) -> Bool {
        lhs.date == rhs.date && lhs.amount == rhs.amount
    }
    
    var id: UUID;
    var date: Date;
    var amount: Decimal;
    @Relationship var parent: Utility?;
}

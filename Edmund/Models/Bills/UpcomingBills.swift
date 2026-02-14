//
//  UpcomingBills.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/2/25.
//

import Foundation
import CoreData
import WidgetKit

/// A type used to store information about an upcoming bill. This is computed from a specific date, and will showcase the bills basic information.
public struct UpcomingBill : Hashable, Equatable, Codable, Identifiable, Sendable {
    public init(name: String, amount: Decimal, dueDate: Date, id: UUID = UUID()) {
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.id = id
    }
    
    public let id: UUID;
    /// The name of the associated bill
    public let name: String;
    /// The amount to be expected on the due date
    public let amount: Decimal;
    /// The due date for this bill
    public let dueDate: Date;
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name);
        hasher.combine(amount);
        hasher.combine(dueDate);
    }
}
/// A collection of `UpcomingBill` computed from a specified date.
public struct UpcomingBillsBundle : Hashable, Equatable, Codable, Sendable { //, TimelineEntry
    public init(date: Date, bills: [UpcomingBill]) {
        self.date = date;
        self.bills = bills;
    }
    
    /// The date that this bundle was computed for
    public let date: Date;
    /// The associated upcoming bills
    public let bills: [UpcomingBill];
    
    public static let example: UpcomingBillsBundle = UpcomingBillsBundle(
        date: .now,
        bills: [
            .init(name: "Apple Music", amount: 9.99, dueDate: Date.fromParts(2025, 7, 2)!),
            .init(name: "iCloud", amount: 2.99, dueDate: Date.fromParts(2025, 7, 5)!),
            .init(name: "Electric", amount: 33.45, dueDate: Date.fromParts(2025, 7, 10)!),
            .init(name: "Amazon Prime", amount: 14.99, dueDate: Date.fromParts(2025, 7, 15)!),
            .init(name: "Water", amount: 40.00, dueDate: Date.fromParts(2025, 7, 22)!),
            .init(name: "YouTube Premium", amount: 20.00, dueDate: Date.fromParts(2026, 7, 29)!)
        ]
    )
}

public struct UpcomingBillsComputation : ~Copyable {
    public static let outputName: String = "upcomingBills.json"
    
    private let data: [Bill];
    
    public init(cx: NSManagedObjectContext) throws {
        let predicate = Bill.fetchRequest();
        let fetch = try cx.fetch(predicate);
        
        self.data = fetch;
    }
    
    public func determineUpcomingBills(for date: Date, calendar: Calendar) -> UpcomingBillsBundle {
        let upcomings = data.compactMap {
            if let next = $0.nextDueDate(calendar: calendar, relativeTo: date) {
                UpcomingBill(name: $0.name, amount: $0.amount, dueDate: next)
            }
            else {
                nil
            }
        }.sorted(using: KeyPathComparator(\UpcomingBill.dueDate))
        
        return .init(date: date, bills: upcomings)
    }
    
    public consuming func process(forDays: Int = 10, calendar: Calendar) -> [UpcomingBillsBundle] {
        let now = Date.now;
        var acc = now;
        let dates: [Date] = (0..<forDays).compactMap { _ in
            if let result = calendar.date(byAdding: .day, value: 1, to: acc) {
                acc = result
                return result
            }
            else {
                return nil
            }
        }
        
        return dates.map { date in
            determineUpcomingBills(for: date, calendar: calendar)
        }
    }
}

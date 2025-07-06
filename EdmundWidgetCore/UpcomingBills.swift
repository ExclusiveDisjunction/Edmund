//
//  UpcomingBills.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/2/25.
//

import Foundation
import SwiftData
import EdmundCore
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
public struct UpcomingBillsBundle : Hashable, Equatable, Codable, Sendable, TimelineEntry {
    public init(date: Date, bills: [UpcomingBill]) {
        self.date = date;
        self.bills = bills;
    }
    
    /// The date that this bundle was computed for
    public let date: Date;
    /// The associated upcoming bills
    public let bills: [UpcomingBill];
}
public struct BillSchematic : Sendable {
    @MainActor
    public init<T>(_ from: T) where T: BillBase {
        self.name = from.name
        self.company = from.company
        self.start = from.startDate
        self.end = from.endDate
        self.period = from.period
        self.amount = from.amount
    }
    
    public let name: String;
    public let company: String;
    public let amount: Decimal;
    public let start: Date;
    public let end: Date?;
    public let period: TimePeriods;
    public var nextDue: Date? {
        return computeNextBillDueDate(start: start, end: end, period: period)
    }
    public func nextDueDate(from: Date) -> Date? {
        return computeNextBillDueDate(start: start, end: end, period: period, relativeTo: from)
    }
}

public struct UpcomingBillsWidgetManager : WidgetDataManager, Sendable {
    public typealias Intermediate = [BillSchematic];
    public typealias Output = [UpcomingBillsBundle];
    
    public static let outputName: String = "upcomingBills.json"
    
    private let data: [BillSchematic];
    private let forDays: Int;
    
    @MainActor
    public init(context: ModelContext, forDays: Int = 10) throws {
        let bills = try context.fetch(FetchDescriptor<Bill>())
        let utilities = try context.fetch(FetchDescriptor<Utility>())
        
        self.data = bills.map { .init($0) } + utilities.map { .init($0) }
        self.forDays = forDays
    }
    
    public func determineUpcomingBills(for date: Date) -> UpcomingBillsBundle {
        let upcomings = data.compactMap {
            if let next = $0.nextDueDate(from: date) {
                UpcomingBill(name: $0.name, amount: $0.amount, dueDate: next)
            }
            else {
                nil
            }
        }.sorted(using: KeyPathComparator(\UpcomingBill.dueDate))
        
        return .init(date: date, bills: upcomings)
    }
    
    public func process() async -> [UpcomingBillsBundle] {
        let calendar = Calendar.current;
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
            determineUpcomingBills(for: date)
        }
    }
}

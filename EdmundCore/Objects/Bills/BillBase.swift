//
//  BillBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

public protocol BillBase : Identifiable, AnyObject {
    var name: String { get set }
    var startDate: Date { get set }
    var endDate: Date? { get set }
    var period: BillsPeriod { get set }
    var kind: BillsKind { get }
    var amount: Decimal { get }
    var company: String { get set }
    var location: String? { get set }
    var notes: String { get set }
}
public extension BillBase {
    var daysSinceStart: Int {
        return weeksSinceStart(from: Date.now)
    }
    func weeksSinceStart(from: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self.startDate, to: from)
        return (components.day ?? 0) / 7;
    }
    var periodsSinceStart: Int {
        return periodsSinceStart(from: .now)
    }
    func periodsSinceStart(from: Date) -> Int {
        let weeks = weeksSinceStart(from: from);
        let periodWeeks = self.period.weeksInPeriod;
        
        return weeks / periodWeeks
    }
    func exactPeriodsSinceStart(from: Date) -> Float {
        let weeks = weeksSinceStart(from: from);
        let periodWeeks = self.period.weeksInPeriod;
        
        return Float(weeks) / Float(periodWeeks)
    }
    var nextBillDate: Date? {
        nextBillDate(from: Date.now)
    }
    func nextBillDate(from: Date) -> Date? {
        if startDate > from {
            return startDate
        }
        else {
            let exact = exactPeriodsSinceStart(from: from);
            
            let nextDate: Date;
            if exact == floorf(exact) { //Exact number of periods, meaning that the result is the current date.
                nextDate = from;
            }
            else {
                let duration = self.period.asDuration * (periodsSinceStart(from: from) + 1);
                guard let computed = duration + startDate else {
                    return nil;
                }
                
                nextDate = computed
            }
            
            if nextDate <= (endDate ?? Date.distantFuture) {
                return nextDate
            }
            else {
                return nil
            }
        }
    }
    var isExpired: Bool {
        if let endDate = endDate {
            Date.now > endDate
        }
        else {
            false
        }
    }
    func pricePer(_ period: BillsPeriod) -> Decimal {
        self.amount * self.period.conversionFactor(period)
    }
    
    var isValid: Bool {
        var list = Set<InvalidBillFields>();
        return Self.validate(name: name, startDate: startDate, endDate: endDate, company: company, location: location, invalid: &list)
    }
    static func validate(name: String, startDate: Date, endDate: Date?, company: String, location: String?, invalid: inout Set<InvalidBillFields>) -> Bool {
        invalid.removeAll()
        
        if name.isEmpty { invalid.insert(.name) }
        if company.isEmpty { invalid.insert(.company) }
        if location?.isEmpty ?? false { invalid.insert(.location) }
        if let endDate = endDate {
            if startDate >= endDate { invalid.insert(.dates) }
        }
        
        return invalid.isEmpty
    }
    
    func update(_ from: any BillBase) {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.endDate
        self.period = from.period
    }
    func update(_ from: BillBaseSnapshot) {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.hasEndDate ? from.endDate : nil
        self.period = from.period
        self.company = from.company
        self.location = from.hasLocation ? from.location : nil
        self.notes = from.notes
    }
}
public struct BillBaseWrapper : Identifiable, Queryable {
    public typealias SortType = BillsSort
    public typealias FilterType = BillsKind
    
    public init(_ data: any BillBase, id: UUID = UUID()) {
        self.data = data
        self.id = id
    }
    
    public var data: any BillBase;
    public var id: UUID;
    
    public static let exampleBills: [BillBaseWrapper] = {
        let bills: [any BillBase] = Bill.exampleBills;
        let utilities: [any BillBase] = Utility.exampleUtility;
        
        return (bills + utilities).map { .init($0) }
    }()
}

@Observable
public class BillBaseSnapshot: Identifiable, Hashable, Equatable {
    init<T>(_ from: T) where T: BillBase {
        self.name = from.name
        self.startDate = from.startDate
        self.hasEndDate = from.endDate != nil
        self.endDate = from.endDate ?? Date.now
        self.period = from.period
        self.company = from.company
        self.hasLocation = from.location != nil
        self.location = from.location ?? String()
        self.notes = from.notes
        self.id = UUID()
    }
    
    public var id: UUID;
    public var name: String;
    public var startDate: Date;
    public var hasEndDate: Bool;
    public var endDate: Date;
    public var period: BillsPeriod;
    public var company: String;
    public var hasLocation: Bool;
    public var location: String;
    public var notes: String;
    
    internal var errors = Set<InvalidBillFields>();
    
    public var isValid: Bool {
        Bill.validate(name: name, startDate: startDate, endDate: hasEndDate ? endDate : nil, company: company, location: hasLocation ? location : nil, invalid: &errors)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
        hasher.combine(company)
        hasher.combine(location)
        hasher.combine(notes)
    }
    public static func ==(lhs: BillBaseSnapshot, rhs: BillBaseSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate && lhs.period == rhs.period && lhs.company == rhs.company && lhs.location == rhs.location && lhs.notes == rhs.notes
    }
    
    public func apply<T>(_ to: T) where T: BillBase {
        to.update(self)
    }
}

public protocol BillBaseSnapshotKind : ElementSnapshot {
    var base: BillBaseSnapshot { get }
}

public struct UpcomingBill : Hashable, Equatable, Codable, Identifiable {
    public init(name: String, amount: Decimal, dueDate: Date, id: UUID = UUID()) {
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.id = id
    }
    
    public let id: UUID;
    public let name: String;
    public let amount: Decimal;
    public let dueDate: Date;
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name);
        hasher.combine(amount);
        hasher.combine(dueDate);
    }
}
public struct UpcomingBillsSnapshot : Hashable, Equatable, Codable {
    public init(date: Date, bills: [UpcomingBill]) {
        self.date = date;
        self.bills = bills;
    }
    
    public var date: Date;
    public var bills: [UpcomingBill];
}

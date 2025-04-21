//
//  BillBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

protocol BillBase : Identifiable, AnyObject {
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
extension BillBase {
    var daysSinceStart: Int {
        let components = Calendar.current.dateComponents([.day], from: self.startDate, to: Date.now)
        return components.day ?? 0
    }
    var periodsSinceStart: Int {
        let days = Float(daysSinceStart);
        let periodDays = self.period.daysInPeriod;
        
        let rawPeriods = days / periodDays
        return Int(rawPeriods.rounded(.towardZero))
    }
    var nextBillDate: Date? {
        let duration = self.period.asDuration * (periodsSinceStart + 1);
        let nextDate = Calendar.current.date(byAdding: duration.asDateComponents, to: self.startDate);
        if let nextDate = nextDate, let endDate = self.endDate {
            if nextDate > endDate {
                return nil
            }
            else {
                return nextDate
            }
        }
        else {
            return nextDate
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
struct BillBaseWrapper : Identifiable, Queryable {
    typealias SortType = BillsSort
    typealias FilterType = BillsKind
    
    init(_ data: any BillBase, id: UUID = UUID()) {
        self.data = data
        self.id = id
    }
    
    var data: any BillBase;
    var id: UUID;
}

@Observable
class BillBaseSnapshot: Identifiable, Hashable, Equatable {
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
    
    var id: UUID;
    var name: String;
    var startDate: Date;
    var hasEndDate: Bool;
    var endDate: Date;
    var period: BillsPeriod;
    var company: String;
    var hasLocation: Bool;
    var location: String;
    var notes: String;
    
    var errors = Set<InvalidBillFields>();
    
    var isValid: Bool {
        Bill.validate(name: name, startDate: startDate, endDate: hasEndDate ? endDate : nil, company: company, location: hasLocation ? location : nil, invalid: &errors)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
        hasher.combine(company)
        hasher.combine(location)
        hasher.combine(notes)
    }
    static func ==(lhs: BillBaseSnapshot, rhs: BillBaseSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate && lhs.period == rhs.period && lhs.company == rhs.company && lhs.location == rhs.location && lhs.notes == rhs.notes
    }
    
    func apply<T>(_ to: T) where T: BillBase {
        to.update(self)
    }
}

protocol BillBaseSnapshotKind : ElementSnapshot {
    
    var base: BillBaseSnapshot { get }
}

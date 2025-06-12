//
//  BillBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

/// A protocol that allows for the enforcement of basic properties that are shared between `Bill` and `Utility` classes.
public protocol BillBase : Identifiable<String>, AnyObject, NamedInspectableElement, NamedEditableElement {
    /// The name of the bill.
    var name: String { get set }
    /// The start date of the bill. This is used to compute the upcoming dates.
    var startDate: Date { get set }
    /// An optional end date for the bill. By convention, `endDate` should be after `startDate`, if a value is provided.
    var endDate: Date? { get set }
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
    /// Any associated notes about the bill.
    var notes: String { get set }
    /// When true, it is known that the bill will automatically be debited to the account.
    var autoPay: Bool { get set }
}
public extension BillBase {
    /// The number of weeks since the start date.
    var weeksSinceStart: Int {
        return weeksSinceStart(from: Date.now)
    }
    /// Determines the number of weeks between `from` and the start date.
    func weeksSinceStart(from: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self.startDate, to: from)
        return (components.day ?? 0) / 7;
    }
    /// Determines how many periods have elapsed since the start date.
    var periodsSinceStart: Int {
        return periodsSinceStart(from: .now)
    }
    /// Determines how many periods have elapsed between `from` and the start date.
    func periodsSinceStart(from: Date) -> Int {
        let weeks = weeksSinceStart(from: from);
        let periodWeeks = self.period.weeksInPeriod;
        
        return weeks / periodWeeks
    }
    /// Returns the exact (including decimal) number of periods have elapsed between `from` and the start date.
    func exactPeriodsSinceStart(from: Date) -> Float {
        let weeks = weeksSinceStart(from: from);
        let periodWeeks = self.period.weeksInPeriod;
        
        return Float(weeks) / Float(periodWeeks)
    }
    /// Estimates the next bill due date
    var nextBillDate: Date? {
        nextBillDate(from: Date.now)
    }
    /// Estimates the next bill due date based on `from`.
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
    
    /// Determines if the values stored in the class are valid.
    var isValid: Bool {
        var list = Set<InvalidBillFields>();
        return Self.validate(name: name, startDate: startDate, endDate: endDate, company: company, location: location, invalid: &list)
    }
    /// Determines if the passed values are valid. If any field is invalid, this will return `false`, and `invalid` will include the invalid fields.
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
    
    /// Updates the values from a specific other instance.
    func update(_ from: any BillBase) {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.endDate
        self.period = from.period
    }
    /// Updates the value from a snapshot value.
    func update(_ from: BillBaseSnapshot) {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.hasEndDate ? from.endDate : nil
        self.period = from.period
        self.company = from.company
        self.location = from.hasLocation ? from.location : nil
        self.notes = from.notes
        self.autoPay = from.autoPay
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
    
    /// A complete list of bill examples, from `Bill` and `Utility`.
    public static let exampleBills: [BillBaseWrapper] = {
        let bills: [any BillBase] = Bill.exampleBills;
        let utilities: [any BillBase] = Utility.exampleUtility;
        
        return (bills + utilities).map { .init($0) }
    }()
}

/// The snapshot for `any BillBase`. This is used inside `BillSnapshot` and `UtilitySnapshot` to simplify the process.
@Observable
public class BillBaseSnapshot: Identifiable, Hashable, Equatable {
    /// Constructs a snapshot around an instance of a `BillBase`.
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
        self.autoPay = from.autoPay;
        self.id = UUID()
    }
    
    public var id: UUID;
    public var name: String;
    public var startDate: Date;
    /// When true, the snapshot will fill the `endDate` property to the `self.endDate` value. However, if false, `endDate` will be `nil`.
    public var hasEndDate: Bool;
    public var endDate: Date;
    public var period: TimePeriods;
    public var company: String;
    /// When true, the snapshot will fill the `location` property to the `self.location` value. However, if false, `location` will be `nil`. 
    public var hasLocation: Bool;
    public var location: String;
    public var notes: String;
    public var autoPay: Bool;
    
    /// The errors present in the snapshot.
    internal var errors = Set<InvalidBillFields>();
    
    /// Determines if the current values are valid.
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
        hasher.combine(autoPay)
    }
    public static func ==(lhs: BillBaseSnapshot, rhs: BillBaseSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate && lhs.period == rhs.period && lhs.company == rhs.company && lhs.location == rhs.location && lhs.notes == rhs.notes && lhs.autoPay == rhs.autoPay
    }

    public func apply<T>(_ to: T) where T: BillBase {
        to.update(self)
    }
}

/// A protocol that enforces that `BillSnapshot` and `UtilitySnapshot` are both `ElementSnapshot`, and contain an instance of `BillBaseSnapshot` for simplification.
public protocol BillBaseSnapshotKind : ElementSnapshot {
    var base: BillBaseSnapshot { get }
}

/// A type used to store information about an upcoming bill. This is computed from a specific date, and will showcase the bills basic information.
public struct UpcomingBill : Hashable, Equatable, Codable, Identifiable {
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
public struct UpcomingBillsBundle : Hashable, Equatable, Codable {
    public init(date: Date, bills: [UpcomingBill]) {
        self.date = date;
        self.bills = bills;
    }
    
    /// The date that this bundle was computed for
    public var date: Date;
    /// The associated upcoming bills
    public var bills: [UpcomingBill];
}

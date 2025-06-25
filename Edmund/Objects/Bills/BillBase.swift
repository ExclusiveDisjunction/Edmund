//
//  BillBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

/// An identifier that can be used for any `BillBase`.
public struct BillBaseID : Hashable, Equatable, RawRepresentable {
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

/// A protocol that allows for the enforcement of basic properties that are shared between `Bill` and `Utility` classes.
public protocol BillBase : Identifiable<BillBaseID>, AnyObject, NamedInspectableElement, NamedEditableElement {
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
public class BillBaseSnapshot: Hashable, Equatable {
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
    }
    
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
    /// Any notes about the bill
    public var notes: String;
    /// If the bill has autopay setup or not
    public var autoPay: Bool;
    
    /// Validates the bill with its current information.
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var result: [ValidationFailure] = []
        
        let name = name.trimmingCharacters(in: .whitespaces)
        let company = company.trimmingCharacters(in: .whitespaces)
        let location = location.trimmingCharacters(in: .whitespaces)
        let id = BillBaseID(name: name, company: company, location: hasLocation ? location : nil)
        
        if !unique.bill(id: id, action: .validate) { result.append(.unique(Bill.identifiers)) }
        
        if name.isEmpty { result.append(.empty("Name")) }
        if company.isEmpty { result.append(.empty("Company")) }
        if hasLocation && location.isEmpty { result.append(.empty("Location")) }
        
        if hasEndDate && endDate < startDate { result.append(.invalidInput("End Date")) }
        
        return result;
    }
    /// Applies data to a specific `BillBase` instance.
    internal func apply<T>(to: T, unique: UniqueEngine) throws(UniqueFailueError<BillBaseID>) where T: BillBase {
        let name = name.trimmingCharacters(in: .whitespaces)
        let company = company.trimmingCharacters(in: .whitespaces)
        let location = location.trimmingCharacters(in: .whitespaces)
        let id = BillBaseID(name: name, company: company, location: hasLocation ? location : nil)
        
        guard unique.bill(id: id, action: .insert) else { throw UniqueFailueError(value: id) }
        
        to.name = name
        to.company = company
        to.location = hasLocation ? location : nil
        to.startDate = startDate
        to.endDate = hasEndDate ? endDate : nil
        to.period = period
        to.notes = notes
        to.autoPay = autoPay
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

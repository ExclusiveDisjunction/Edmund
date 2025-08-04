//
//  BalanceTools.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation
import SwiftData
import Charts

/// A structure encoding credit and debit values.
public struct BalanceInformation : Sendable, Hashable, Equatable, Codable {
    public init(credit: Decimal, debit: Decimal) {
        self.credit = credit
        self.debit = debit
    }
    public init() {
        self.credit = 0
        self.debit = 0
    }
    
    /// The amount of money that has come in.
    public var credit: Decimal;
    /// The amount of money that has left.
    public var debit: Decimal;
    
    /// The current balance.
    public var balance: Decimal {
        credit - debit
    }
    
    public static func +(lhs: BalanceInformation, rhs: BalanceInformation) -> BalanceInformation {
        .init(credit: lhs.credit + rhs.credit, debit: lhs.debit + rhs.debit)
    }
    public static func +=(lhs: inout BalanceInformation, rhs: BalanceInformation) {
        lhs.credit += rhs.credit
        lhs.debit += rhs.debit
    }
}

/// A single element balance representing the balance of some `BoundPairParent`.
public struct SimpleBalance : Identifiable, Sendable {
    public init(_ name: String, _ credit: Decimal, _ debit: Decimal, id: UUID = UUID()) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = id
    }
    
    public let id: UUID;
    /// The name of the assocated element.
    public let name: String;
    /// The money that has been credited to the element.
    public let credit: Decimal;
    /// The money that has been debited from the element.
    public let debit: Decimal;
    /// The current balance of the element.
    public var balance: Decimal {
        credit - debit
    }
}

/// A tree like balance representing the balances of several different types.
public struct DetailedBalance : Identifiable, Sendable {
    public init(_ name: String,  _ credit: Decimal, _ debit: Decimal, children: [DetailedBalance]? = nil, id: UUID = UUID()) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = id
        self.children = children
    }
    
    public let id: UUID
    /// The name of the assocated element.
    public let name: String;
    /// The money that has been credited to the element.
    public let credit: Decimal;
    /// The money that has been debited from the element.
    public let debit: Decimal;
    /// The children elements of the current balance information.
    public let children: [DetailedBalance]?;
    
    /// The current balance of the element.
    public var balance: Decimal {
        credit - debit
    }
    
}

/// A structure encoding the balances of any hashable type.
public struct BalanceAssociation<T> where T: Hashable {
    fileprivate let data: [T: BalanceInformation];
    
    /// Converts the inner data into instances of `SimpleBalance`, while optionally sorting.
    @MainActor
    private consuming func process(sorted: Bool, map: ((T, BalanceInformation)) throws -> SimpleBalance) rethrows -> [SimpleBalance] {
        let result = try self.data.map(map)
    
        return sorted ? result.sortedByBalances() : result
    }
    
    /// Obtains the total balance of all children elements.
    @MainActor
    public consuming func totalBalance() -> BalanceInformation {
        self.data.values.reduce(BalanceInformation()) { old, balance in
            old + balance
        }
    }
    
    /// Converts the internal data into `SimpleBalance` instances.
    /// - Parameters:
    ///     - name: A closure that converts an element `T` value into a `String`, which will be used as the name for the `SimpleBalance`. This can throw, and the function will rethrow that value.
    ///     - sorted: When `true`, the returned list will be sorted by the `SimpleBalance.balance` parameter.
    /// - Returns:
    ///     A list of `SimpleBalance` instances encoding the internal balances.
    /// - Throws:
    ///         Any error that is thrown when `name` is called.
    @MainActor
    public consuming func intoSimpleBalances(name: (T) throws -> String, sorted: Bool = true) rethrows -> [SimpleBalance] {
        try self.process(sorted: sorted) { (element, balance) in
            let elementName = try name(element);
            return SimpleBalance(elementName, balance.credit, balance.debit)
        }
    }
    /// Converts the internal data into `DetailedBalance` instances
    /// - Parameters:
    ///     - name: A closure that converts an element `T` value into a `String`, which will be used as the name for the `DetailedBalance`. This can throw, and the function will rethrow that value.
    ///     - total: A running total of the balances computed from this structure.
    /// - Returns:
    ///     A list of `DetailedBalance` instances encoding the internal balances.
    /// - Throws:
    ///     Any error that is thrown when `name` is called.
    @MainActor
    public consuming func intoDetailedBalance(name: (T) throws -> String, total: inout BalanceInformation) rethrows -> [DetailedBalance] {
        try self.data.map { (key, value) in
            total += value
            let elementName = try name(key)
            
            return DetailedBalance(elementName, value.credit, value.debit)
        }
    }
}
extension BalanceAssociation : Sequence {
    public typealias Iterator = [T: BalanceInformation].Iterator
    
    public func makeIterator() -> [T: BalanceInformation].Iterator {
        self.data.makeIterator()
    }
}
extension BalanceAssociation where T == String {
    /// Converts the internal data into `SimpleBalance` instances, using the internal `String`'s value as the balance's name.
    /// - Parameters:
    ///     - sorted: When `true`, the returned list will be sorted by the `SimpleBalance.balance` parameter.
    /// - Returns:
    ///     A list of `SimpleBalance` instances encoding the internal balances.
    @MainActor
    public consuming func intoSimpleBalances(sorted: Bool = true) -> [SimpleBalance] {
        self.process(sorted: sorted) { (name, balance) in
                .init(name, balance.credit, balance.debit)
        }
    }
    /// Converts the internal data into `DetailedBalance` instances, using the internal `String`'s value as the balance's name.
    /// - Parameters:
    ///     - total: A running total of the balances computed from this structure.
    /// - Returns:
    ///     A list of `DetailedBalance` instances encoding the internal balances.
    @MainActor
    public consuming func intoDetailedBalance(total: inout BalanceInformation) -> [DetailedBalance] {
        self.data.map { (key, value) in
            total += value
            
            return DetailedBalance(key, value.credit, value.debit)
        }
    }
}
extension BalanceAssociation where T: NamedElement {
    /// Converts the internal data into `SimpleBalance` instances, using the internal `NamedElement.name` property as the balance's name.
    /// - Parameters:
    ///     - sorted: When `true`, the returned list will be sorted by the `SimpleBalance.balance` parameter.
    /// - Returns:
    ///     A list of `SimpleBalance` instances encoding the internal balances.
    @MainActor
    public consuming func intoSimpleBalances(sorted: Bool = true) -> [SimpleBalance] {
        self.process(sorted: sorted) { (element, balance) in
                .init(element.name, balance.credit, balance.debit)
        }
    }
    /// Converts the internal data into `DetailedBalance` instances, , using the internal `NamedElement.name` property as the balance's name.
    /// - Parameters:
    ///     - total: A running total of the balances computed from this structure.
    /// - Returns:
    ///     A list of `DetailedBalance` instances encoding the internal balances.
    @MainActor
    public consuming func intoDetailedBalance(total: inout BalanceInformation) -> [DetailedBalance] {
        self.data.map { (key, value) in
            total += value
            
            return DetailedBalance(key.name, value.credit, value.debit)
        }
    }
}

/// A structure containing the tree of balances obtained from a list of `T`.
public struct BoundPairBalances<T> where T: BoundPairParent {
    fileprivate let data: [T: BalanceAssociation<T.C>];
    
    /// Converts the top level balances into instances of `SimpleBalance`.
    /// - Parameters:
    ///     - sorted: When `true`, the returned list will be sorted by balance.
    /// - Returns: A list of `SimpleBalance` instances, containing the balances of the top level (`T`) elements
    @MainActor
    public consuming func intoSimpleBalances(sorted: Bool = true) -> [SimpleBalance] {
        let result = self.data.mapValues { $0.totalBalance() }.map {
            SimpleBalance($0.key.name, $0.value.credit, $0.value.debit)
        }
        
        return sorted ? result.sortedByBalances() : result
    }
    /// Converts the top level balances, and all sub-balances into a list of `DetailedBalance`.
    /// - Parameters:
    ///     - sorted: When `true`, the returned list will be sorted by balance.
    /// - Returns: A list of `DetailedBalance` containing all balances from all levels of the hierarchy.
    @MainActor
    public consuming func intoDetailedBalances(sorted: Bool = true) -> [DetailedBalance] {
        let result : [DetailedBalance] = self.data.map { (account, children) in
            var balance: BalanceInformation = .init();
            let subBalances: [DetailedBalance] = children.intoDetailedBalance(total: &balance)
            
            return DetailedBalance(
                account.name,
                balance.credit,
                balance.debit,
                children: subBalances
            )
        }
        
        return sorted ? result.sortedByBalances() : result
    }
}
extension BoundPairBalances : Sequence {
    public typealias Iterator = [T: BalanceAssociation<T.C>].Iterator;
    
    public func makeIterator() -> Dictionary<T, BalanceAssociation<T.C>>.Iterator {
        self.data.makeIterator()
    }
}

/// A collection of tools to group transactions together.
@MainActor
public struct BalanceResolver<T> where T: BoundPairParent, T.C: TransactionHolder {
    public init(_ on: [T]) {
        self.on = on
    }
    
    private let on: [T]
    
    /// Computes the top level balances for the passed in `T` values.
    public consuming func computeBalances() -> BalanceAssociation<T> {
        var result: [T: BalanceInformation] = [:];
        for account in on {
            var balance = BalanceInformation();
            let subAccounts = account.children
            
            for subAccount in subAccounts {
                guard let transactions = subAccount.transactions else { continue }
                
                for trans in transactions {
                    balance.credit += trans.credit
                    balance.debit += trans.debit
                }
            }
            
            result[account] = balance
        }
        
        return .init(data: result)
    }
    /// Computes the tree of balances on teh passed in `T` values.
    public consuming func computeSubBalances() -> BoundPairBalances<T> {
        var result: [T: BalanceAssociation<T.C>] = [:];
        for account in on {
            var tmpResult: [T.C: BalanceInformation] = [:]
            
            let subAccounts = account.children
            for subAccount in subAccounts {
                var balance = BalanceInformation();
                guard let transactions = subAccount.transactions else { continue }
                for trans in transactions {
                    balance.credit += trans.credit
                    balance.debit += trans.debit
                }
                
                tmpResult[subAccount] = balance
            }
            
            result[account] = BalanceAssociation(data: tmpResult)
        }
        
        return BoundPairBalances(data: result)
    }
}

/// A structure that encodes the month and year of some specific date.
public struct MonthYear : Hashable, Codable, Comparable, Sendable, CustomStringConvertible {
    /// Creates the `MonthYear` instance from  specific values.
    /// - Parameters:
    ///     - year: The target year
    ///     - month: The target month
    public init(_ year: Int, _ month: Int) {
        self.year = year
        self.month = month
    }
    /// Attempts to create the `MonthYear` from a date.
    /// - Parameters:
    ///     - date: The date to extract from
    ///     - calendar: The calendar used to extract components.
    /// - Note: This will return `nil` if the calendar is not able to extract the required components out of `date`.
    public init?(date: Date, calendar: Calendar = .current) {
        let comp = calendar.dateComponents([.year, .month], from: date);
        guard let year = comp.year, let month = comp.month else {
            return nil;
        }
        self.year = year
        self.month = month
    }
    
    /// The year associated with this data
    public let year: Int;
    /// The month associated with this data
    public let month: Int;
    
    public var description: String {
        "Month: \(month) Year: \(year)"
    }
    
    /// Attempts to convert the structure into a `Date` instance.
    /// - Note: This will return `nil` if the current `Calendar` is not able to resolve this structure to a specific date.
    /// - Note: This will always return the first day of that specific month & year.
    public var asDate: Date? {
        self.asDate(calendar: .current)
    }
    /// Attempts to convert the structure into a `Date` instance using a specified calendar.
    /// - Parameters:
    ///     - calendar: The calendar to use when performing the conversion.
    /// - Note: This will return `nil` if the  `Calendar` instance is not able to resolve this structure to a specific date.
    /// - Note: This will always return the first day of that specific month & year.
    public func asDate(calendar: Calendar) -> Date? {
        calendar.date(from: .init(year: self.year, month: self.month, day: 1))
    }
    
    /// Attempts to obtain the current month and year from `Date.now`.
    /// - Note: This will return `nil` if the current `Calendar` is not able to extract the required components to construct this instance.
    public static var now: MonthYear? {
        self.init(date: .now)
    }
    /// Attempts to obtain the current month and year from `Date.now` using a specific calendar.
    /// - Parameters:
    ///     - calendar: The calendar to use for date component extraction.
    /// - Note: This will return `nil` if the `Calendar` passed is not able to extract the required components to construct this instance.
    public static func now(calendar: Calendar) -> MonthYear? {
        self.init(date: .now, calendar: calendar)
    }
    
    public static func < (lhs: MonthYear, rhs: MonthYear) -> Bool {
        if lhs.year == rhs.year {
            lhs.month < rhs.month
        }
        else {
            lhs.year < rhs.year
        }
    }
}

/// A collection of functions that can process transactions into different forms for usable information.
@MainActor
public struct TransactionResolver {
    public init(_ entries: [LedgerEntry]) {
        self.entries = entries;
    }
    
    private let entries: [LedgerEntry];
    
    /// Splits all transactions by their month and year.
    public consuming func splitByMonth() -> [MonthYear: [LedgerEntry]] {
        var result: [MonthYear: [LedgerEntry]] = [:];
        
        for entry in entries {
            guard let monthYear = MonthYear(date: entry.date) else {
                continue;
            }
            
            if result[monthYear] == nil {
                result[monthYear] = [];
            }
            
            result[monthYear]?.append(entry);
        }
        
        return result
    }
}

public extension [SimpleBalance] {
    /// Sorts the instances by the balances, in reverse order.
    func sortedByBalances() -> Self {
        return self.sorted(using: KeyPathComparator(\.balance, order: .reverse))
    }
}
public extension [DetailedBalance] {
    /// Sorts the instances by balances, in reverse order.
    func sortedByBalances() -> Self {
        let cmp = KeyPathComparator(\DetailedBalance.balance, order: .reverse)
        return self.map {
            .init(
                $0.name,
                $0.credit,
                $0.debit,
                children: $0.children?.sorted(using: cmp),
                id: $0.id
            )
        }.sorted(using: cmp)
    }
}

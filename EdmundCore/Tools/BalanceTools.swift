//
//  BalanceTools.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation
import SwiftData
import Charts

public struct BalanceInformation : Sendable, Hashable, Equatable, Codable {
    public init(credit: Decimal, debit: Decimal) {
        self.credit = credit
        self.debit = debit
    }
    public init() {
        self.credit = 0
        self.debit = 0
    }
    
    public var credit: Decimal;
    public var debit: Decimal;
    
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

public protocol BalanceEncoder: Identifiable {
    var name: String { get }
    var balance: Decimal { get }
}
public protocol ParentBalanceEncoder: BalanceEncoder {
    associatedtype Child: BalanceEncoder

    var children: [Child]? { get }
}

public struct SimpleBalance : Identifiable, BalanceEncoder, Sendable {
    public init(_ name: String, _ credit: Decimal, _ debit: Decimal, id: UUID = UUID()) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = id
    }
    
    public let id: UUID;
    public let name: String;
    public let credit: Decimal;
    public let debit: Decimal;
    public var balance: Decimal {
        credit - debit
    }
}

public struct DetailedBalance : Identifiable, ParentBalanceEncoder, Sendable {
    public init(_ name: String,  _ credit: Decimal, _ debit: Decimal, children: [DetailedBalance]? = nil, id: UUID = UUID()) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = id
        self.children = children
    }
    
    public let id: UUID
    public let name: String;
    public let credit: Decimal;
    public let debit: Decimal;
    public let children: [DetailedBalance]?;
    public var balance: Decimal {
        credit - debit
    }
    
}


public struct BalanceAssociation<T> where T: Hashable {
    fileprivate let data: [T: BalanceInformation];
    
    @MainActor
    private consuming func process(sorted: Bool, map: ((T, BalanceInformation)) throws -> SimpleBalance) rethrows -> [SimpleBalance] {
        let result = try self.data.map(map)
    
        return sorted ? result.sortedByBalances() : result
    }
    
    @MainActor
    public consuming func totalBalance() -> BalanceInformation {
        self.data.values.reduce(BalanceInformation()) { old, balance in
            old + balance
        }
    }
    
    @MainActor
    public consuming func intoSimpleBalances(name: (T) throws -> String, sorted: Bool = true) rethrows -> [SimpleBalance] {
        try self.process(sorted: sorted) { (element, balance) in
            let elementName = try name(element);
            return SimpleBalance(elementName, balance.credit, balance.debit)
        }
    }
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
    @MainActor
    public consuming func intoSimpleBalances(sorted: Bool = true) -> [SimpleBalance] {
        self.process(sorted: sorted) { (name, balance) in
                .init(name, balance.credit, balance.debit)
        }
    }
    @MainActor
    public consuming func intoDetailedBalance(total: inout BalanceInformation) -> [DetailedBalance] {
        self.data.map { (key, value) in
            total += value
            
            return DetailedBalance(key, value.credit, value.debit)
        }
    }
}
extension BalanceAssociation where T: NamedElement {
    @MainActor
    public consuming func intoSimpleBalances(sorted: Bool = true) -> [SimpleBalance] {
        self.process(sorted: sorted) { (element, balance) in
                .init(element.name, balance.credit, balance.debit)
        }
    }
    @MainActor
    public consuming func intoDetailedBalance(total: inout BalanceInformation) -> [DetailedBalance] {
        self.data.map { (key, value) in
            total += value
            
            return DetailedBalance(key.name, value.credit, value.debit)
        }
    }
}


public struct BoundPairBalances<T> where T: BoundPairParent {
    fileprivate let data: [T: BalanceAssociation<T.C>];
    
    @MainActor
    public consuming func intoSimpleBalances(sorted: Bool = true) -> [SimpleBalance] {
        let result = self.data.mapValues { $0.totalBalance() }.map {
            SimpleBalance($0.key.name, $0.value.credit, $0.value.debit)
        }
        
        return sorted ? result.sortedByBalances() : result
    }
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

@MainActor
public struct BalanceResolver<T> where T: BoundPairParent, T.C: TransactionHolder {
    public init(_ on: [T]) {
        self.on = on
    }
    
    private let on: [T]
    
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

public struct MonthYear : Hashable, Codable, Comparable, Sendable, CustomStringConvertible {
    public init(_ year: Int, _ month: Int) {
        self.year = year
        self.month = month
    }
    public init?(date: Date, calendar: Calendar = .current) {
        let comp = calendar.dateComponents([.year, .month], from: date);
        guard let year = comp.year, let month = comp.month else {
            return nil;
        }
        self.year = year
        self.month = month
    }
    
    public let year: Int;
    public let month: Int;
    
    public var description: String {
        "Month: \(month) Year: \(year)"
    }
    
    public var asDate: Date? {
        self.asDate(calendar: .current)
    }
    public func asDate(calendar: Calendar) -> Date? {
        calendar.date(from: .init(year: self.year, month: self.month, day: 1))
    }
    
    public static var currentMonthYear: MonthYear? {
        self.init(date: .now)
    }
    public static func currentMonthYear(calendar: Calendar) -> MonthYear? {
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

extension [SimpleBalance] {
    func sortedByBalances() -> Self {
        return self.sorted(using: KeyPathComparator(\.balance, order: .reverse))
    }
}
public extension [DetailedBalance] {
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

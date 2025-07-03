//
//  BalanceTools.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation
import SwiftData
import Charts
import EdmundCore

struct BalanceResolver {
    @MainActor
    static func computeBalances<T>(_ on: [T]) -> Dictionary<T, (Decimal, Decimal)> where T: BoundPairParent, T.C: TransactionHolder {
        var result: [T: (Decimal, Decimal)] = [:];
        for account in on {
            var credits: Decimal = 0.0
            var debits: Decimal = 0.0
            let subAccounts = account.children
            
            for subAccount in subAccounts {
                guard let transactions = subAccount.transactions else { continue }
                
                for trans in transactions {
                    credits += trans.credit
                    debits += trans.debit
                }
            }
            
            result[account] = (credits, debits)
        }
        
        return result
    }
    @MainActor
    static func computeSubBalances<T>(_ on: [T]) -> Dictionary<T, Dictionary<T.C, (Decimal, Decimal)>> where T: BoundPairParent, T.C: TransactionHolder {
        var result: [T: [T.C: (Decimal, Decimal)]] = [:];
        for account in on {
            var tmpResult: [T.C: (Decimal, Decimal)] = [:]
            
            let subAccounts = account.children
            for subAccount in subAccounts {
                var credits: Decimal = 0
                var debits: Decimal = 0
                guard let transactions = subAccount.transactions else { continue }
                for trans in transactions {
                    credits += trans.credit
                    debits += trans.debit
                }
                
                tmpResult[subAccount] = (credits, debits)
            }
            
            result[account] = tmpResult;
        }
        
        return result
    }
}

public struct MonthYear : Hashable, Codable, Comparable, Sendable {
    public init(_ year: Int, _ month: Int) {
        self.year = year
        self.month = month
    }
    public init(date: Date) {
        let comp = Calendar.current.dateComponents(Set([Calendar.Component.year, Calendar.Component.month]), from: date);
        self.year = comp.year ?? 0
        self.month = comp.month ?? 0
    }
    
    public let year: Int;
    public let month: Int;
    
    public var asDate: Date {
        Calendar.current.date(from: DateComponents(year: self.year, month: self.month, day: 1)) ?? Date.distantFuture
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
public struct TransactionResolver {
    public static func splitByMonth(_ entries: [LedgerEntry]) -> [MonthYear: [LedgerEntry]] {
        var result: [MonthYear: [LedgerEntry]] = [:];
        
        for entry in entries {
            let monthYear = MonthYear(date: entry.date);
            
            if result[monthYear] == nil {
                result[monthYear] = [];
            }
            
            result[monthYear]?.append(entry);
        }
        
        return result
    }
}

extension Dictionary where Key: NamedElement, Value == (Decimal, Decimal) {
    func intoSimpleBalances() -> [SimpleBalance] {
        self.map { (element, balances) in
                .init(element.name, balances.0, balances.1)
        }
    }
}
extension Dictionary where Key: NamedElement, Key: BoundPairParent, Key.C: TransactionHolder, Key.C: NamedElement, Value == Dictionary<Key.C, (Decimal, Decimal)> {
    func intoSimpleBalances() -> [SimpleBalance] {
        self.map { (account, subAccount) in
            var credit: Decimal = 0, debit: Decimal = 0;
            
            for balance in subAccount.values {
                credit += balance.0;
                debit += balance.1
            }
            
            return .init(account.name, credit, debit)
        }
    }
    func intoDetailedBalances() -> [DetailedBalance] {
        self.map { (account, subAccount) in
            var credit: Decimal = 0, debit: Decimal = 0;
            
            let children: [DetailedBalance] = subAccount.map { (acc, balance) in
                credit += balance.0;
                debit += balance.1
                
                return .init(acc.name, balance.0, balance.1)
            }
            
            return .init(account.name, credit, debit, children: children)
        }
    }
}
extension Array where Element: BalanceEncoder {
    mutating func sortByBalances() {
        self.sort(using: KeyPathComparator(\.balance, order: .reverse))
    }
    func sortedByBalances() -> Self {
        return self.sorted(using: KeyPathComparator(\.balance, order: .reverse))
    }
}
extension Array where Element: ParentBalanceEncoder {
    mutating func sortByBalances() {
        for item in self {
            if var children = item.children {
                children.sortByBalances()
            }
        }
        
        self.sort(using: KeyPathComparator(\.balance, order: .reverse))
    }
}

protocol BalanceEncoder: Identifiable {
    var name: String { get }
    var balance: Decimal { get }
}
protocol ParentBalanceEncoder: Identifiable, BalanceEncoder {
    associatedtype Child: BalanceEncoder
    
    var name: String { get }
    var balance: Decimal { get  }
    var children: [Child]? { get }
}

struct SimpleBalance : Identifiable, BalanceEncoder, Sendable {
    init(_ name: String, _ credit: Decimal, _ debit: Decimal) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = UUID()
    }
    
    let id: UUID;
    let name: String;
    let credit: Decimal;
    let debit: Decimal;
    var balance: Decimal {
        credit - debit
    }
}

struct DetailedBalance : Identifiable, ParentBalanceEncoder, Sendable {
    init(_ name: String,  _ credit: Decimal, _ debit: Decimal, children: [DetailedBalance]? = nil) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = UUID()
        self.children = children
    }
    
    let id: UUID
    let name: String;
    let credit: Decimal;
    let debit: Decimal;
    var balance: Decimal {
        credit - debit
    }
    var children: [DetailedBalance]?;
}

/*
@Observable
class ComplexBalance : Identifiable, ParentBalanceEncoder, @unchecked Sendable {
    init(_ name: String, subs: [SimpleBalance]) {
        self.name = name;
        self.subs = subs;
        
        self.subs.sort { $0.balance > $1.balance }
    }
    
    let name: String;
    let subs: [SimpleBalance];
    let expanded = true;
    var children: [SimpleBalance]? {
        get { subs }
        set { subs = newValue ?? [] }
    }
    var balance: Decimal {
        subs.reduce(into: 0) { $0 += $1.balance }
    }
}
*/

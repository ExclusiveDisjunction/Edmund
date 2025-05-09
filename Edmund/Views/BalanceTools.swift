//
//  BalanceTools.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation
import EdmundCore
import SwiftData

struct BalanceResolver {
    static func computeBalances<T>(_ on: [T]) -> Dictionary<T, (Decimal, Decimal)> where T: BoundPairParent, T.C: TransactionHolder {
        var result: [T: (Decimal, Decimal)] = [:];
        for account in on {
            var credits: Decimal = 0.0
            var debits: Decimal = 0.0
            guard let subAccounts = account.children else { continue }
            
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
    static func computeSubBalances<T>(_ on: [T]) -> Dictionary<T, Dictionary<T.C, (Decimal, Decimal)>> where T: BoundPairParent, T.C: TransactionHolder {
        var result: [T: [T.C: (Decimal, Decimal)]] = [:];
        for account in on {
            var tmpResult: [T.C: (Decimal, Decimal)] = [:]
            
            guard let subAccounts = account.children else { continue }
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
extension Dictionary where Key: EdmundCore.InspectableElement, Value == (Decimal, Decimal) {
    func intoSimpleBalances() -> [SimpleBalance] {
        self.map { (element, balances) in
                .init(element.name, balances.0, balances.1)
        }
    }
}
extension Dictionary where Key: InspectableElement, Key: BoundPairParent, Key.C: TransactionHolder, Key.C: InspectableElement, Value == Dictionary<Key.C, (Decimal, Decimal)> {
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
    func intoComplexBalances() -> [ComplexBalance] {
        self.map {
            .init($0.key.name, subs: $0.value.intoSimpleBalances())
        }
    }
}
extension Array where Element: BalanceEncoder {
    mutating func sortByBalances() {
        self.sort(using: KeyPathComparator(\.balance, order: .reverse))
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
    var name: String { get set }
    var balance: Decimal { get }
}
protocol ParentBalanceEncoder: Identifiable, BalanceEncoder {
    associatedtype Child: BalanceEncoder
    
    var name: String { get set }
    var balance: Decimal { get  }
    var children: [Child]? { get set }
}

struct SimpleBalance : Identifiable, BalanceEncoder {
    init(_ name: String, _ credit: Decimal, _ debit: Decimal) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = UUID()
    }
    
    var id: UUID;
    var name: String;
    var credit: Decimal;
    var debit: Decimal;
    var balance: Decimal {
        credit - debit
    }
}

struct DetailedBalance : Identifiable, ParentBalanceEncoder {
    init(_ name: String,  _ credit: Decimal, _ debit: Decimal, children: [DetailedBalance]? = nil) {
        self.name = name
        self.credit = credit
        self.debit = debit
        self.id = UUID()
        self.children = children
    }
    
    var id: UUID
    var name: String;
    var credit: Decimal;
    var debit: Decimal;
    var balance: Decimal {
        credit - debit
    }
    var children: [DetailedBalance]?;
}

@Observable
class ComplexBalance : Identifiable, ParentBalanceEncoder {
    init(_ name: String, subs: [SimpleBalance]) {
        self.name = name;
        self.subs = subs;
        
        self.subs.sort { $0.balance > $1.balance }
    }
    
    var name: String;
    var subs: [SimpleBalance];
    var children: [SimpleBalance]? {
        get { subs }
        set { subs = newValue ?? [] }
    }
    var balance: Decimal {
        subs.reduce(into: 0) { $0 += $1.balance }
    }
    var expanded = true;
}

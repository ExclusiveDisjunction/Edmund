//
//  BillDatapoint.swift
//  Edmund
//
//  Created by Hollan Sellars on 9/3/25.
//

import Foundation

extension BillDatapoint : Hashable, Equatable {
    public convenience init(_ amount: Decimal?, index: Int) {
        self.init(amount, index: index, parent: nil)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(amount)
    }
    public static func ==(lhs: BillDatapoint, rhs: BillDatapoint) -> Bool {
        lhs.id == rhs.id && lhs.amount == rhs.amount
    }
}

public struct ResolvedBillHistory : Identifiable, Sendable {
    public init(from: BillDatapoint, date: Date?, id: UUID = UUID()) {
        self.id = id
        self.amount = from.amount
        self.date = date
    }
    
    public let id: UUID;
    public let amount: Decimal?;
    public var date: Date?;
}
@Observable
public class BillHistorySnapshot : Identifiable, Hashable, Equatable {
    public init(date: Date?, id: UUID = UUID()) {
        self.id = id
        self.date = date
        self.amount = .init()
        self.skipped = false
    }
    public init(from: BillDatapoint, date: Date?, id: UUID = UUID()) {
        self.id = id
        self.date = date
        if let value = from.amount {
            self.skipped = false
            self.amount = .init(rawValue: value)
        }
        else {
            self.skipped = true
            self.amount = .init()
        }
    }
    
    public let id: UUID;
    public var skipped: Bool;
    public var amount: CurrencyValue;
    public var date: Date?;
    
    public var trueAmount: CurrencyValue? {
        get {
            skipped ? nil : amount
        }
        set {
            if let value = newValue {
                self.skipped = false
                self.amount = value
            }
            else {
                self.skipped = true
            }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(skipped)
        hasher.combine(amount)
        hasher.combine(date)
    }
    public static func ==(lhs: BillHistorySnapshot, rhs: BillHistorySnapshot) -> Bool {
        lhs.trueAmount == rhs.trueAmount && lhs.date == rhs.date
    }
}


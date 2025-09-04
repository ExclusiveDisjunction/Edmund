//
//  BillDatapoint.swift
//  Edmund
//
//  Created by Hollan Sellars on 9/3/25.
//

import Foundation

extension BillDatapoint : Hashable, Equatable, BillHistoryRecord {
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

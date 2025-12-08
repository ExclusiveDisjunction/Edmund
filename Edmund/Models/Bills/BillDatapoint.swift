//
//  BillDatapoint.swift
//  Edmund
//
//  Created by Hollan Sellars on 9/3/25.
//

import Foundation

extension BillDatapoint {
    public var amount: Decimal? {
        get { self.internalAmount as Decimal? }
        set { self.internalAmount = newValue as NSDecimalNumber? }
    }
}

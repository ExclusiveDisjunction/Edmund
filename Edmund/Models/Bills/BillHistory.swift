//
//  BillBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI
import Foundation

public struct ResolvedBillHistory : Identifiable, Sendable {
    public init(from: BillDatapoint, date: Date?, id: UUID = UUID()){
        self.id = id
        self.amount = from.amount
        self.date = date
    }
    
    public let id: UUID;
    public let amount: Decimal?;
    public var date: Date?;
}

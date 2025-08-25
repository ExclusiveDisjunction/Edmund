//
//  BillHistory.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/24/25.
//

import Foundation
import SwiftData

public protocol BillHistoryRecord : Identifiable<Int>, PersistentModel {
    associatedtype Parent: BillBase;
    
    init(_ amount: Decimal?, index: Int, parent: Self.Parent?);
    
    var amount: Decimal? { get set }
    var parent: Self.Parent? { get }
}

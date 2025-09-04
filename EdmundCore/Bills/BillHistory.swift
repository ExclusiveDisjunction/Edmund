//
//  BillHistory.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/24/25.
//

import Foundation
import SwiftData

public protocol BillHistoryRecord : Identifiable<Int>, PersistentModel {
    init(_ amount: Decimal?, index: Int);
    
    var id: Int { get set }
    var amount: Decimal? { get set }
}

//
//  TransactionHolder.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation

public protocol TransactionHolder {
    var transactions: [LedgerEntry]? { get set }
}

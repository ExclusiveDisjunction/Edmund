//
//  TransactionHolder.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation

/// Represents a type that holds `LedgerEntry` values.
public protocol TransactionHolder {
    /// The transactions associated with this type.
    var transactions: [LedgerEntry]? { get set }
}

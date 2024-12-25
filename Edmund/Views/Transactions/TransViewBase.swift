//
//  TransViewBase.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import Foundation;

protocol TransViewBase : Identifiable {
    func compile_deltas() -> Dictionary<String, Decimal>;
    @discardableResult
    func create_transactions() throws(TransactionError) -> [LedgerEntry];
    @discardableResult
    func validate() -> Bool;
    
    func clear();
}

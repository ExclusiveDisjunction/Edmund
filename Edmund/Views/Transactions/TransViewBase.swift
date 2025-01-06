//
//  TransViewBase.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import Foundation;

protocol TransViewBase : Identifiable {
    func compile_deltas() -> Dictionary<AccountPair, Decimal>?;
    func create_transactions() -> [LedgerEntry]?;
    func validate() -> Bool;
    
    func clear();
}

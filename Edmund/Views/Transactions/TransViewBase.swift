//
//  TransViewBase.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import Foundation;

protocol TransViewBase : Identifiable {
    func compile_deltas() -> Dictionary<UUID, Decimal>?;
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]?;
    func validate() -> Bool;
    
    func clear();
}

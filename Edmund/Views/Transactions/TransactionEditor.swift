//
//  TransViewBase.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import Foundation;

protocol TransactionEditor : Identifiable {
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]?;
    func validate() -> Bool;
}

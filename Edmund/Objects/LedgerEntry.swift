//
//  LedgerEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

/// The displayed value of the ledger style
public enum LedgerStyle: Int, Identifiable, CaseIterable {
    /// Display credits as 'money in', and debits as 'money out'
    case none = 0
    /// Display credits as 'debit', and debits as 'credit'
    case standard = 1
    /// Display credits as 'credit', and debits as 'debit'
    case reversed = 2
    
    /// A UI ready description of what the value is
    public var description: LocalizedStringKey {
        switch self {
            case .none: "Do not show as Accounting Style"
            case .standard: "Standard Accounting Style"
            case .reversed: "Reversed Accounting Style"
        }
    }
    /// The value to use for a 'credit' field.
    public var displayCredit: LocalizedStringKey {
        switch self {
            case .none: "Money In"
            case .standard: "Debit"
            case .reversed: "Credit"
        }
    }
    /// The value to use for a 'debit' field.
    public var displayDebit: LocalizedStringKey {
        switch self {
            case .none: "Money Out"
            case .standard: "Credit"
            case .reversed: "Debit"
        }
    }
    public var id: Self { self }
}

extension LedgerEntry : EditableElement, InspectableElement, TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Transaction",
            plural:   "Transactions",
            inspect:  "Inspect Transaction",
            edit:     "Edit Transaction",
            add:      "Add Transaction"
        )
    }
    
    public func makeInspectView() -> LedgerEntryInspect {
        LedgerEntryInspect(self)
    }
    public static func makeEditView(_ snap: LedgerEntrySnapshot) -> LedgerEntryEdit {
        LedgerEntryEdit(snap)
    }
}

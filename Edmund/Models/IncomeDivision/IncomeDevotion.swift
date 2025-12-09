//
//  DevotionBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation
import SwiftUI

public enum DevotionGroup : Int16, Displayable, Identifiable, CaseIterable, Codable {
    case need = 0
    case want = 1
    case savings = 2
    
    public var display: LocalizedStringKey {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
        }
    }
    
    public var id: Self { self }
}

extension IncomeDevotion {
    

    /*
    public func update(_ snap: IncomeDevotionSnapshot, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.amount = switch snap.amount {
        case .amount(let v): .amount(v.rawValue)
        case .percent(let v): .percent(v.rawValue)
        case .remainder: .remainder
        }
        self.account = snap.account
        self.group = snap.group
    }
     */
}

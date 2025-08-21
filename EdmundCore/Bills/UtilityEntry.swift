//
//  UtilityEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftData
import Foundation

extension UtilityDatapoint: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(amount)
    }
    public static func ==(lhs: UtilityDatapoint, rhs: UtilityDatapoint) -> Bool {
        lhs.id == rhs.id && lhs.amount == rhs.amount
    }
}

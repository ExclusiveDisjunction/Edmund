//
//  UtilityEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    /// An instance used to keep the order of utility data points.
    @Model
    public class UtilityDatapoint : Identifiable, Hashable, Equatable {
        public init(_ amount: Decimal = 0, index: Int, parent: Utility? = nil) {
            self.id = index
            self.parent = parent
            self.amount = amount
        }
    
        /// Where the data point lies in the greater storage array.
        public var id: Int;
        /// How much the datapoint cost
        public var amount: Decimal;
        /// The owning utility.
        @Relationship
        public var parent: Utility?;
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(amount)
        }
        public static func ==(lhs: UtilityDatapoint, rhs: UtilityDatapoint) -> Bool {
            lhs.id == rhs.id && lhs.amount == rhs.amount
        }
    }
}

public typealias UtilityDatapoint = EdmundModelsV1_1.UtilityDatapoint;

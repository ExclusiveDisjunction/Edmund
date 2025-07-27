//
//  BudgetSpendingGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1 {
    @Model
    public final class BudgetSpendingGoal : BudgetGoal {
        public init(category: SubCategory?, amount: Decimal, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = category
            self.amount = amount
            self.parent = parent
        }
        public convenience init(snapshot: BudgetGoalSnapshot<SubCategory>, unique: UniqueEngine) {
            self.init(
                category: snapshot.association,
                amount: snapshot.amount.rawValue,
                parent: nil,
            )
        }
        
        public var id: UUID;
        public var amount: Decimal;
        @Relationship
        public var association: SubCategory?;
        @Relationship
        public var parent: BudgetMonth?;
        
        public func duplicate() -> BudgetSpendingGoal {
            .init(category: self.association, amount: self.amount, parent: nil)
        }
        
        public func makeSnapshot() -> BudgetGoalSnapshot<SubCategory> {
            return .init(self)
        }
        public static func makeBlankSnapshot() -> BudgetGoalSnapshot<SubCategory> {
            return .init()
        }
        public func update(_ from: BudgetGoalSnapshot<SubCategory>, unique: UniqueEngine) {
            self.association = from.association
            self.amount = amount
        }
    }
}

public typealias BudgetSpendingGoal = EdmundModelsV1.BudgetSpendingGoal

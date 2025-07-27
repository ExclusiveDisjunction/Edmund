//
//  BudgetSavingsGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1 {
    @Model
    public final class BudgetSavingsGoal : BudgetGoal {
        public init(account: SubAccount?, amount: Decimal, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = account
            self.amount = amount
            self.parent = parent
        }
        public convenience init(snapshot: BudgetGoalSnapshot<SubAccount>, unique: UniqueEngine) {
            self.init(
                account: snapshot.association,
                amount: snapshot.amount.rawValue,
                parent: nil,
            )
        }
        
        public var id: UUID;
        public var amount: Decimal;
        @Relationship
        public var association: SubAccount?;
        @Relationship
        public var parent: BudgetMonth?;
        
        public func duplicate() -> BudgetSavingsGoal {
            .init(account: self.association, amount: self.amount, parent: nil)
        }
        
        public func makeSnapshot() -> BudgetGoalSnapshot<SubAccount> {
            return .init(self)
        }
        public static func makeBlankSnapshot() -> BudgetGoalSnapshot<SubAccount> {
            return .init()
        }
        public func update(_ from: BudgetGoalSnapshot<SubAccount>, unique: UniqueEngine) {
            self.association = from.association
            self.amount = amount
        }
    }
}

public typealias BudgetSavingsGoal = EdmundModelsV1.BudgetSavingsGoal

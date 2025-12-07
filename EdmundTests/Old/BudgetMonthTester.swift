//
//  BudgetMonthTester.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/30/25.
//

import Foundation
import Testing
import SwiftData

struct BudgetMonthTester {
    @MainActor
    @Test
    func testStartEndDates() throws {
        let container = try Containers.debugContainer()
        let budget = BudgetMonth.blankBudgetMonth(forDate: .init(2025, 7))
        container.context.insert(budget)
        
        #expect(budget.start == Date.fromParts(2025, 7, 1)!);
        #expect(budget.end == Date.fromParts(2025, 7, 31)!)
    }
}

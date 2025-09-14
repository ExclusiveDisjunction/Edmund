//
//  BudgetMonthEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct BudgetMonthEdit : View {
    let source: BudgetMonthSnapshot;
    
    var body: some View {
        VStack {
            HStack {
                Text(source.title)
                    .font(.title)
                Spacer()
            }
            
            TabView {
                BudgetIncomeEdit(snapshot: source)
                    .tabItem {
                        Text("Income")
                    }
                
                BudgetSpendingGoalEdit(snapshot: source)
                    .tabItem {
                        Text("Spending")
                    }
                
                BudgetSavingGoalEdit(snapshot: source)
                    .tabItem {
                        Text("Savings")
                    }
            }
        }
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @Query var budgets: [BudgetMonth];
    
    BudgetMonthEdit(source: budgets.first!.makeSnapshot())
        .padding()
}

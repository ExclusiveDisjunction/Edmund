//
//  BudgetMonthEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import SwiftUI
import SwiftData

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

#Preview {
    DebugContainerView {
        BudgetMonthEdit(source: try! BudgetMonth.getExampleBudget().makeSnapshot())
            .padding()
    }
}

//
//  BudgetGoalsErrorView.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/22/25.
//

import SwiftUI

struct BudgetGoalsErrorView : View {
    let e: BudgetComputationError;
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Edmund is not able to present this budget. Please report this issue.")
                .font(.title3)
            
            Divider()
            Text("Details:")
            
            switch e {
                case .invalidBudget(let start, let end):
                    Text("The start and/or end dates of the budget could not be obtained. Values: \(String(describing: start)), \(String(describing: end))")
                case .swiftData(let inner):
                    Text("The transactions could not be obtained from the data store. Inner error: \(inner.localizedDescription)")
            }
            
            Spacer()
        }
    }
}

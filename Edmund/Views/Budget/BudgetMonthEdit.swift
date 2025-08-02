//
//  BudgetMonthEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import SwiftUI
import EdmundCore

struct BudgetMonthEdit : View {
    @Bindable var source: BudgetMonthSnapshot;
    
    var body: some View {
        VStack {
            HStack {
                Text(source.title)
                    .font(.title)
                Spacer()
            }
            Spacer()
        }
    }
}

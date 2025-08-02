//
//  BudgetMonthInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import EdmundCore
import SwiftUI

struct BudgetMonthInspect : View {
    var over: BudgetMonth;
    
    var body: some View {
        VStack {
            HStack {
                Text(over.title)
                    .font(.title)
                Spacer()
            }
            
            Spacer()
        }
    }
}

//
//  IncomeDivisionPicker.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/24/25.
//

import SwiftUI
import SwiftData

struct IncomeDivisionPicker : View {
    init(_ title: LocalizedStringKey, selection: Binding<IncomeDivision?>, id: Binding<IncomeDivision.ID?>, budget: Binding<YearRowID?>) {
        self.title = title
        self._selection = selection
        self._selectedID = id
        self._selectedBudgetID = budget
    }
    
    @Binding var selectedBudgetID: YearRowID?;
    @State private var budget: BudgetMonth?;
    @Binding var selectedID: IncomeDivision.ID?;
    @Binding var selection: IncomeDivision?;
    
    let title: LocalizedStringKey;
    
    var body: some View {
        VStack {
            BudgetPicker(id: $selectedBudgetID, selected: $budget, label: "Budget:")
            
            Picker(title, selection: $selectedID) {
                Text("(None)")
                    .italic()
                    .tag(nil as IncomeDivision.ID?)
                
                if let selectedBudget = budget {
                    ForEach(selectedBudget.income) { division in
                        Text(division.name)
                            .tag(division.id)
                            .strikethrough(division.isFinalized)
                    }
                }
            }
        }.onChange(of: selectedBudgetID) { _, newValue in
            if newValue == nil {
                self.selectedID = nil;
            }
        }
        .onChange(of: selectedID) { _, newValue in
            let new: IncomeDivision?;
            guard let id = newValue, let selectedBudget = budget else {
                self.selection = nil;
                return;
            }
            
            if let target = selectedBudget.income.first(where: { $0.id == id } ) {
                target.lastViewed = .now
                new = target
            }
            else {
                new = nil
            }
            
            withAnimation {
                selection = new
            }
        }
    }
}

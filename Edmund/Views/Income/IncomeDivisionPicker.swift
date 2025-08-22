//
//  IncomeDivisionPicker.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/24/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDivisionPicker : View {
    init(_ title: LocalizedStringKey, selection: Binding<IncomeDivision?>, id: Binding<IncomeDivision.ID?>) {
        self.title = title
        self._selection = selection
        self._selectedID = id
    }
    
    @Query(filter: #Predicate<IncomeDivision> { !$0.isFinalized }, sort: [SortDescriptor(\IncomeDivision.name, order: .forward)]) private var budgetInstances: [IncomeDivision];
    @Query(filter: #Predicate<IncomeDivision> { $0.isFinalized }, sort: [SortDescriptor(\IncomeDivision.name, order: .forward)]) private var finBudgetInstances: [IncomeDivision];
    @Binding var selectedID: IncomeDivision.ID?;
    @Binding var selection: IncomeDivision?;
    
    let title: LocalizedStringKey;
    
    var body: some View {
        Picker(title, selection: $selectedID) {
            Text("(None)")
                .italic()
                .tag(nil as IncomeDivision.ID?)
            
            ForEach(budgetInstances) { instance in
                Text(instance.name).tag(instance.id)
            }
            
            if !finBudgetInstances.isEmpty {
                Section("Finalized") {
                    ForEach(finBudgetInstances) { instance in
                        Text(instance.name).tag(instance.id)
                    }
                }
            }
        }.onChange(of: selectedID) { _, newValue in
            let new: IncomeDivision?;
            guard let id = newValue else {
                self.selection = nil;
                return;
            }
            
            if let target = budgetInstances.first(where: { $0.id == id } ) {
                target.lastViewed = .now
                new = target
            }
            else if let target = finBudgetInstances.first(where: { $0.id == id } ) {
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

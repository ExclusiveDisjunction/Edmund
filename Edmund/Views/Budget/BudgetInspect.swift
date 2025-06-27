//
//  BudgetIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/10/25.
//

import SwiftUI
import SwiftData

struct BudgetInspect : View {
    @Query private var budgetInstances: [BudgetInstance];
    @State private var selectedBudgetID: BudgetInstance.ID?;
    @State private var selectedBudget: BudgetInstance?;
    @State private var selectedDevotions: Set<AnyDevotion.ID> = .init();
    @State private var editingBudget: BudgetInstance?;
    
    @State private var isSearching: Bool = false;
    @State private var isAdding: Bool = false;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    private static func computedAmount(_ budget: BudgetInstance, _ target: AnyDevotion) -> Decimal {
        switch target {
            case .amount(let a): a.amount
            case .percent(let p): p.amount * budget.amount
            case .remainder(_): budget.remainderValue
        }
    }
    
    @ViewBuilder
    private func fullSize(_ budget: BudgetInstance) -> some View {
        Table(budget.allDevotions, selection: $selectedDevotions) {
            TableColumn("Name", value: \.name)
            TableColumn("Amount") { row in
                Text(Self.computedAmount(budget, row), format: .currency(code: currencyCode))
            }
            TableColumn("Computed Amount") { row in
                switch row {
                    case .amount(let a): Text(a.amount, format: .currency(code: currencyCode))
                    case .percent(let p): Text(p.amount * budget.amount, format: .currency(code: currencyCode))
                    case .remainder(_): Text(budget.remainderValue, format: .currency(code: currencyCode))
                }
            }
            TableColumn("Destination") { row in
                CompactNamedPairInspect(row.account)
            }
#if os(macOS)
            .width(150)
#endif
        }
    }
    
    @ViewBuilder
    private func compact(_ budget: BudgetInstance) -> some View {
        HStack {
            Text("Name")
                .font(.subheadline)
                .bold()
                .padding(.leading)
            
            Spacer()
            
            Text("Computed Amount")
                .font(.subheadline)
                .bold()
        }.padding([.leading, .trailing, .top])
        List(budget.allDevotions, selection: $selectedDevotions) { devotion in
            HStack {
                Text(devotion.name)
                Spacer()
                Text(Self.computedAmount(budget, devotion), format: .currency(code: currencyCode))
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Budget:")
                
                Picker("", selection: $selectedBudgetID) {
                    Text("None")
                        .tag(nil as BudgetInstance.ID?)
                    ForEach(budgetInstances, id: \.id) { budget in
                        HStack {
                            Text(budget.name)
                            Text(budget.amount, format: .currency(code: currencyCode))
                            Spacer()
                            Text("Last modified:")
                            Text(budget.lastUpdated.formatted(date: .abbreviated, time: .omitted))
                        }.tag(budget.id)
                    }
                }.labelsHidden()
                
                #if os(iOS)
                Spacer()
                #endif
                
                Button(action: {
                    isAdding = true;
                }) {
                    Image(systemName: "plus")
                }
                
                Button(action: {
                    isSearching = true;
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
            
            Divider()
            
            if let budget = selectedBudget {
                HStack {
                    Text("Total Income:")
                    Text(budget.amount, format: .currency(code: currencyCode))
                    Spacer()
                    
                    Button(action: {
                        editingBudget = budget
                    }) {
                        Label("Edit Budget", systemImage: "pencil")
                    }
                }
                
                if horizontalSizeClass == .compact {
                    compact(budget)
                }
                else {
                    fullSize(budget)
                }
            }
            else {
                Spacer()
                Text("Select a budget to begin")
                    .italic()
                Spacer()
                    
            }
        }.padding()
            .navigationTitle("Budget")
            .onChange(of: selectedBudgetID) { _, newValue in
                if let id = newValue, let target = budgetInstances.first(where: { $0.id == id } ) {
                    selectedBudget = target
                    target.lastViewed = .now
                }
            }
            .toolbar {
                
            }
            .sheet(item: $editingBudget) { budget in
                
            }
            .sheet(isPresented: $isSearching) {
                BudgetSearch(result: $selectedBudgetID)
            }
            .sheet(isPresented: $isAdding) {
                BudgetAddView($selectedBudgetID)
            }
        
    }
}

#Preview {
    BudgetInspect()
        .modelContainer(Containers.debugContainer)
}

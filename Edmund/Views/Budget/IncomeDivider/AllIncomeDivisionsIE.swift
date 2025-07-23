//
//  BudgetIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/10/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomdeDividerIE : View {
    var data: IncomeDividerInstance;
    var snapshot: IncomeDividerInstanceSnapshot?;
    var hash: Int;
    
    private var isEditing: Bool {
        snapshot != nil
    }
    private var unsavedChanges: Bool {
        snapshot != nil && hash != snapshot?.hashValue
    }
    
    var body: some View {
        VStack {
            
        }.interactiveDismissDisabled(unsavedChanges)
            
    }
}

struct AllIncomeDivisionsIE : View {
    @Query(sort: [SortDescriptor(\IncomeDividerInstance.name, order: .forward)]) private var budgetInstances: [IncomeDividerInstance];
    @State private var selectedBudgetID: IncomeDividerInstance.ID?;
    @State private var selectedBudget: IncomeDividerInstance?;
    @State private var selectedDevotions: Set<AnyDevotion.ID> = .init();
    @State private var editingBudget: IncomeDividerInstance?;
    
    @State private var showInspector: Bool = false;
    @State private var isSearching: Bool = false;
    @State private var isAdding: Bool = false;
    @State private var showGraph: Bool = false;
    @State private var finalizeWarning: Bool = false;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.pagesLocked) private var pagesLocked;
    
    private static func computedAmount(_ budget: IncomeDividerInstance, _ target: AnyDevotion) -> Decimal {
        switch target {
            case .amount(let a): a.amount
            case .percent(let p): p.amount * budget.amount
            case .remainder(_): budget.remainderValue
            default: .nan
        }
    }
    private func apply(_ budget: IncomeDividerInstance) {
        fatalError()
    }
    
    @ViewBuilder
    private func fullSize(_ budget: IncomeDividerInstance) -> some View {
        Table(budget.allDevotions, selection: $selectedDevotions) {
            TableColumn("Name", value: \.name)
            TableColumn("Devotion") { row in
                switch row {
                    case .amount(let a): Text(a.amount, format: .currency(code: currencyCode))
                    case .percent(let p): Text(p.amount, format: .percent)
                    case .remainder(_): Text("Remainder")
                    default: Text("internalError")
                }
            }
            TableColumn("Amount") { row in
                Text(Self.computedAmount(budget, row), format: .currency(code: currencyCode))
            }
            TableColumn("Group") { row in
                Text(row.group.display)
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
    private func compact(_ budget: IncomeDividerInstance) -> some View {
        HStack {
            Text("Name")
                .font(.subheadline)
                .bold()
                .padding(.leading)
            
            Spacer()
            
            Text("Amount")
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
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if let budget = selectedBudget {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: {
                    showGraph = true
                }) {
                    Label("Graph", systemImage: "chart.pie")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(action: {
                    //editingBudget = budget
                    pagesLocked.wrappedValue = !pagesLocked.wrappedValue
                }) {
                    Label("Edit Income Division", systemImage: "pencil")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(action: {
                    finalizeWarning = true
                }) {
                    Label("Finalize", systemImage: "checkmark")
                }
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button(action: {
                    isAdding = true;
                }) {
                    Text("Add new")
                }
                
                Button(action: {
                    fatalError()
                }) {
                    Text("Copy from another")
                }
            } label: {
                Label("Add Income Division", systemImage: "plus")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                isSearching = true;
            }) {
                Label("Search Divisions", systemImage: "magnifyingglass")
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Income Division:")
                
                Picker("", selection: $selectedBudgetID) {
                    Text("None")
                        .tag(nil as IncomeDividerInstance.ID?)
                    ForEach(budgetInstances, id: \.id) {
                        Text($0.name).tag($0.id)
                            .strikethrough($0.isFinalized)
                    }
                }.labelsHidden()
                
                #if os(iOS)
                Spacer()
                #endif
            }
            
            Divider()
            
            if let budget = selectedBudget {
                IncomeDivisionInspect(data: budget)
                /*
                HStack {
                    Text("Total Income:")
                    Text(budget.amount, format: .currency(code: currencyCode))
                    
                    Spacer()
                    
                    Text("Amount Free:", comment: "This in context is the amount of money left from the income of the divider, minus all devotions. This is similar to variance.")
                    Text(budget.variance, format: .currency(code: currencyCode))
                }
                
                if horizontalSizeClass == .compact {
                    compact(budget)
                }
                else {
                    fullSize(budget)
                }
                 */
            }
            else {
                Spacer()
                Text("Select a budget to begin")
                    .italic()
                Spacer()
                    
            }
        }.padding()
            .navigationTitle("Income Division")
            .onChange(of: selectedBudgetID) { _, newValue in
                let new: IncomeDividerInstance?;
                if let id = newValue, let target = budgetInstances.first(where: { $0.id == id } ) {
                    target.lastViewed = .now
                    new = target
                }
                else {
                    new = nil
                }
                
                withAnimation {
                    selectedBudget = new
                }
            }
            .toolbar(content: toolbarContent)
            .sheet(isPresented: $isSearching) {
                AllIncomeDivisionsSearch(result: $selectedBudgetID)
            }
            .sheet(isPresented: $isAdding) {
                IncomeDivisionAdd($selectedBudgetID)
            }
            .sheet(isPresented: $showGraph) {
                if let selected = selectedBudget {
                    DevotionGroupsGraph(from: selected)
                }
                else {
                    VStack {
                        Text("internalError")
                        Button("Ok", action: { showGraph = false } )
                    }
                }
            }
            .confirmationDialog("Warning! Finalizing an income division will apply transactions to the ledger. Do you want to continue?", isPresented: $finalizeWarning, titleVisibility: .visible) {
                Button("Ok", action: {
                    if let budget = selectedBudget {
                        apply(budget)
                    }
                    else {
                        print("Note: Budget finalize was called, but the budget was not selected.")
                    }
                })
                
                Button("Cancel", role: .cancel, action: { finalizeWarning = false })
            }
            .inspector(isPresented: $showInspector) {
                
            }
    }
}

#Preview {
    DebugContainerView {
        AllIncomeDivisionsIE()
    }
}

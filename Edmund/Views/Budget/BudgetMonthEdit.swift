//
//  BudgetMonthEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import SwiftUI
import EdmundCore

struct BudgetMonthIncomeEdit : View {
    @Bindable var snapshot: BudgetMonthSnapshot;
    @State private var selection = Set<BudgetIncomeSnapshot.ID>();
    @State private var closeLook: BudgetIncomeSnapshot? = nil;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    private func add() {
        withAnimation {
            snapshot.income.append(.init())
        }
    }
    private func remove(_ selection: Set<BudgetIncomeSnapshot.ID>? = nil) {
        let trueSelection = selection == nil ? self.selection : selection!;
        
        guard !trueSelection.isEmpty else {
            return
        }
        
        withAnimation {
            snapshot.income.removeAll(where: { trueSelection.contains($0.id) } )
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    add()
                } label: {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                
                Button {
                    remove()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }.buttonStyle(.borderless)
                
#if os(iOS)
                EditButton()
#endif
            }
            
            Table($snapshot.income, selection: $selection) {
                TableColumn("Name") { $row in
                    if horizontalSizeClass == .compact {
                        HStack {
                            Text(row.name)
                            Spacer()
                            Text(row.amount.rawValue, format: .currency(code: currencyCode))
                        }.swipeActions(edge: .trailing) {
                            Button {
                                closeLook = row
                            } label: {
                                Label("Close Look", systemImage: "magnifyingglass")
                            }.tint(.green)
                        }
                    }
                    else {
                        TextField("", text: $row.name)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                TableColumn("Amount") { $row in
                    CurrencyField(row.amount)
                }
                
                TableColumn("Has Date") { $row in
                    Toggle("", isOn: $row.hasDate)
                        .labelsHidden()
                }
                
                TableColumn("Date") { $row in
                    if row.hasDate {
                        DatePicker("", selection: $row.date, displayedComponents: .date)
                    }
                    else {
                        EmptyView()
                    }
                }
            }.contextMenu(forSelectionType: BudgetIncomeSnapshot.ID.self) { selection in
                Button {
                    if let id = selection.first, let target = snapshot.income.first(where: { $0.id == id } ), selection.count == 1 {
                        closeLook = target
                    }
                } label: {
                    Label("Close Look", systemImage: "magnifyingglass")
                }.disabled(selection.count != 1)
                
                Button {
                    add()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                
                Button {
                    remove(selection)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundStyle(.red)
                }.disabled(selection.isEmpty)
            }
        }.sheet(item: $closeLook) { target in
            BudgetIncomeEditCloseLook(snapshot: target)
        }
    }
}

struct BudgetMonthGoalEdit<T> : View where T: BoundPair, T: TransactionHolder, T: TypeTitled, T.P: TypeTitled, T.P.C == T {
    let data: Binding<[BudgetGoalSnapshot<T>]>;
    let title: LocalizedStringKey;
    @State private var selection = Set<BudgetGoalSnapshot<T>.ID>();
    @State private var closeLook: BudgetGoalSnapshot<T>? = nil;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    private func add() {
        withAnimation {
            data.wrappedValue.append(.init())
        }
    }
    private func remove(_ selection: Set<BudgetGoalSnapshot<T>.ID>? = nil) {
        let trueSelection = selection == nil ? self.selection : selection!;
        
        guard !trueSelection.isEmpty else {
            return
        }
        
        withAnimation {
            data.wrappedValue.removeAll(where: { trueSelection.contains($0.id) } )
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    add()
                } label: {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                
                Button {
                    remove()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }.buttonStyle(.borderless)
                
                #if os(iOS)
                EditButton()
                #endif
            }
            
            Table(data, selection: $selection) {
                TableColumn(title) { $row in
                    if horizontalSizeClass == .compact {
                        VStack {
                            HStack {
                                Text(row.amount.rawValue, format: .currency(code: currencyCode))
                                Text(row.period.display)
                                Spacer()
                            }
                            
                            HStack {
                                Spacer()
                                CompactNamedPairInspect(row.association)
                            }
                        }.swipeActions(edge: .trailing) {
                            Button {
                                closeLook = row
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }.tint(.green)
                        }
                    }
                    else {
                        NamedPairPicker<T>($row.association)
                    }
                }
                
                TableColumn("Goal") { $row in
                    CurrencyField(row.amount)
                }
                
                TableColumn("Period") { $row in
                    Picker("", selection: $row.period) {
                        ForEach(MonthlyTimePeriods.allCases) {
                            Text($0.display).tag($0)
                        }
                    }.labelsHidden()
                }
                
                TableColumn("Monthly Goal") { $row in
                    Text(row.monthlyGoal, format: .currency(code: currencyCode))
                }
            }.contextMenu(forSelectionType: BudgetGoalSnapshot<T>.ID.self) { selection in
                Button {
                    if let id = selection.first, let target = data.wrappedValue.first(where: { $0.id == id } ), selection.count == 1 {
                        closeLook = target
                    }
                } label: {
                    Label("Close Look", systemImage: "magnifyingglass")
                }.disabled(selection.count != 1)
                
                Button {
                    add()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                
                Button {
                    remove(selection)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundStyle(.red)
                }.disabled(selection.isEmpty)
            }
        }.sheet(item: $closeLook) { target in
            BudgetMonthGoalCloseLook(over: target)
        }
    }
}

struct BudgetMonthSpendingGoalEdit : View {
    @Bindable var snapshot :BudgetMonthSnapshot;
    
    var body: some View {
        BudgetMonthGoalEdit(data: $snapshot.spendingGoals, title: "Category")
    }
}

struct BudgetMonthSavingGoalEdit : View {
    @Bindable var snapshot: BudgetMonthSnapshot;
    
    var body: some View {
        BudgetMonthGoalEdit(data: $snapshot.savingsGoals, title: "Account")
    }
}

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
                BudgetMonthIncomeEdit(snapshot: source)
                    .tabItem {
                        Text("Income")
                    }
                
                BudgetMonthSpendingGoalEdit(snapshot: source)
                    .tabItem {
                        Text("Spending")
                    }
                
                BudgetMonthSavingGoalEdit(snapshot: source)
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

//
//  BudgetGoalEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/22/25.
//

import SwiftUI
import SwiftData

struct BudgetGoalEdit<T> : View where T: NamedElement & TransactionHolder & Hashable & PersistentModel {
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
    
    @ViewBuilder
    private func compactTitleColumn(row: BudgetGoalSnapshot<T>) -> some View {
        VStack {
            HStack {
                Text(row.amount.rawValue, format: .currency(code: currencyCode))
                Text(row.period.display)
                Spacer()
            }
            
            HStack {
                Spacer()
                ElementDisplayer(value: row.association)
            }
        }.swipeActions(edge: .trailing) {
            Button {
                closeLook = row
            } label: {
                Image(systemName: "magnifyingglass")
            }.tint(.green)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: add) {
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
                        compactTitleColumn(row: row)
                    }
                    else {
                        ElementPicker($row.association)
                    }
                }
                
                TableColumn("Goal") { $row in
                    CurrencyField(row.amount)
                }
                
                TableColumn("Period") { $row in
                    EnumPicker(value: $row.period)
                }
                
                TableColumn("Monthly Goal") { $row in
                    Text(row.monthlyGoal, format: .currency(code: currencyCode))
                }
            }.contextMenu(forSelectionType: BudgetGoalSnapshot<T>.ID.self) { selection in
                let resolved = data.wrappedValue.filter { selection.contains($0.id) }
                
                Button {
                    closeLook = resolved.first
                } label: {
                    Label("Close Look", systemImage: "magnifyingglass")
                }.disabled(resolved.count != 1)
                
                Button(action: add) {
                    Label("Add", systemImage: "plus")
                }
                
                Button {
                    remove(selection)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundStyle(.red)
                }.disabled(resolved.isEmpty)
            }
        }.sheet(item: $closeLook) { target in
            BudgetGoalCloseEdit(over: target)
        }
    }
}

struct BudgetSpendingGoalEdit : View {
    @Bindable var snapshot :BudgetMonthSnapshot;
    
    var body: some View {
        BudgetGoalEdit(data: $snapshot.spendingGoals, title: "Category")
    }
}

struct BudgetSavingGoalEdit : View {
    @Bindable var snapshot: BudgetMonthSnapshot;
    
    var body: some View {
        BudgetGoalEdit(data: $snapshot.savingsGoals, title: "Account")
    }
}

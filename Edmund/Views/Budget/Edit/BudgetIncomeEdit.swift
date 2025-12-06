//
//  BudgetIncomeEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/22/25.
//

import SwiftUI
import SwiftData

struct BudgetIncomeEdit : View {
    @Bindable var snapshot: BudgetMonthSnapshot;
    @State private var selection = Set<ShallowIncomeDivisionSnapshot.ID>();
    @State private var closeLook: ShallowIncomeDivisionSnapshot? = nil;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    private func add() {
        withAnimation {
            snapshot.income.append(.init())
        }
    }
    private func remove(_ selection: Set<ShallowIncomeDivisionSnapshot.ID>? = nil) {
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
            Text("Note: To edit the income devotions, please use the income divider tool.")
                .italic()
            Text("Note: Any row with a check mark cannot be edited, as it is finalized.")
                .italic()
            
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
            
            Table($snapshot.income, selection: $selection) {
                TableColumn("Name") { $row in
                    if horizontalSizeClass == .compact {
                        HStack {
                            Text(row.name)
                            Spacer()
                            Text(row.amount.rawValue, format: .currency(code: currencyCode))
                            
                            if row.isFinalized {
                                Image(systemName: "checkmark")
                            }
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
                            .disabled(row.isFinalized)
                    }
                }
                
                TableColumn("Amount") { $row in
                    CurrencyField(row.amount)
                        .disabled(row.isFinalized)
                }
                
                TableColumn("Income Kind") { $row in
                    EnumPicker(value: $row.kind)
                        .disabled(row.isFinalized)
                }
                
                TableColumn("Deposit To") { $row in
                    ElementPicker($row.depositTo)
                        .disabled(row.isFinalized)
                }
                
                TableColumn("") { $row in
                    if row.isFinalized {
                        Image(systemName: "checkmark")
                    }
                }.width(30)
            }.contextMenu(forSelectionType: ShallowIncomeDivisionSnapshot.ID.self) { selection in
                Button {
                    if let id = selection.first, let target = snapshot.income.first(where: { $0.id == id } ), selection.count == 1 {
                        closeLook = target
                    }
                } label: {
                    Label("Close Look", systemImage: "magnifyingglass")
                }.disabled(selection.count != 1)
                
                Button(action: add) {
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
            IncomeDivisionPropertiesEditor(snapshot: target, isSheet: true)
        }
    }
}

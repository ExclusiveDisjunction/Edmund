//
//  BudgetIncomeInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/22/25.
//

import EdmundCore
import SwiftUI
import SwiftData

struct BudgetMonthIncomeInspect : View {
    var over: BudgetMonthInspectManifest
    @State private var selection: Set<IncomeDivision.ID> = .init();
    @State private var closeLook: IncomeDivision? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        Table(over.over.income, selection: $selection) {
            TableColumn("Name") { income in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(income.name)
                        Spacer()
                        Text(income.amount, format: .currency(code: currencyCode))
                    }.swipeActions(edge: .trailing) {
                        Button {
                            closeLook = income
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }.tint(.green)
                    }
                }
                else {
                    Text(income.name)
                }
            }
            TableColumn("Amount") { income in
                Text(income.amount, format: .currency(code: currencyCode))
            }
            
            TableColumn("Income Kind") { income in
                EnumDisplayer(value: income.kind)
            }
            
            TableColumn("Deposit To") { income in
                ElementDisplayer(value: income.depositTo)
            }
            
            TableColumn("") { income in
                if income.isFinalized {
                    Image(systemName: "checkmark")
                }
            }.width(30)
        }
        .contextMenu(forSelectionType: IncomeDivision.ID.self) { selection in
            Button {
                if let id = selection.first, let target = over.over.income.first(where: { $0.id == id }), selection.count == 1 {
                    self.closeLook = target
                }
            } label: {
                Label("Close Look", systemImage: "magnifyingglass")
            }.disabled(selection.count != 1)
        }
        .sheet(item: $closeLook) { target in
            IncomeDivisionCloseInspect(data: target)
        }
    }
}

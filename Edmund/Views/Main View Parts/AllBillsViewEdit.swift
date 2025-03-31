//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

struct GeneralActionsPanel: View {
    var on_add: () -> Void;
    var on_edit: () -> Void;
    var on_delete: () -> Void;
    
    var body: some View {
        HStack {
            Button(action: on_add) {
                Image(systemName: "plus")
            }
            Button(action: on_edit) {
                Image(systemName: "pencil")
            }
            Button(action: on_delete) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
        }
    }
}

struct AllBillsViewEdit : View {
    @State var showSheet = false;
    @State private var selectedBill: Bill?;
    @State private var query: QueryProvider<Bill> = .init(.name);
    @State private var tableSelected: Bill.ID?;
    
#if os(macOS)
    private var popoverMinWidth = CGFloat(300)
#else
    private var popoverMinWidth = CGFloat(400)
#endif
    
    @Environment(\.modelContext) var modelContext;
        
    @Query private var bills: [Bill]
    private var sortedBills: [Bill] {
        query.apply(bills)
    }
    
    private func add_bill() {
        withAnimation {
            let new_bill = Bill(name: "", amount: 0, kind: .subscription)
            modelContext.insert(new_bill)
            selectedBill = new_bill
        }
    }
    private func remove_selected() {
        withAnimation {
            if let resolved = bills.first(where: {$0.id == tableSelected}) {
                modelContext.delete(resolved)
            }
        }
    }
    private func edit_selected() {
        if let resolved = bills.first(where: {$0.id == tableSelected}) {
            self.selectedBill = resolved;
        }
    }
    
    private var totalPPW: Decimal {
        bills.reduce(0, {$0 + $1.pricePerWeek})
    }

    var body: some View {
        VStack {
            Table(self.sortedBills, selection: $tableSelected) {
                TableColumn("Name", value: \Bill.name)
                TableColumn("Kind", value: \.kind.rawValue)
                TableColumn("Amount") { bill in
                    Text(bill.amount, format: .currency(code: "USD"))
                }
                TableColumn("Frequency") { bill in
                    Text(bill.period.rawValue)
                }
                TableColumn("Price per Week") { bill in
                    Text(bill.pricePerWeek, format: .currency(code: "USD"))
                }
            }
            
            HStack {
                Spacer()
                Text("Total Price Per Week:")
                Text(self.totalPPW, format: .currency(code: "USD"))
            }
        }.padding().sheet(item: $selectedBill) { bill in
            BillEditor(bill: bill)
        }.toolbar {
            QueryButton(provider: query)
            GeneralActionsPanel(on_add: add_bill, on_edit: edit_selected, on_delete: remove_selected)
        }.navigationTitle("Bills")
    }
}

#Preview {
    AllBillsViewEdit().modelContainer(ModelController.previewContainer)
}

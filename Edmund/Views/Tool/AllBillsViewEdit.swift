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
    @State private var tableSelected: Bill.ID?;
    @Environment(\.modelContext) var modelContext;
    
    let kind: BillsKind // The kind of bills to display
        
    @Query private var bills: [Bill]
 
    init(kind: BillsKind) {
        let isSimple = kind == .simple
        
        let predicate = #Predicate<Bill> { bill in
            bill.isSimple == isSimple
        };
        
        _bills = Query(filter: predicate, sort: \.name)
        self.kind = kind
    }
    
    private func add_bill() {
        withAnimation {
            let new_bill = Bill(name: "", amount: 0, kind: self.kind)
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
            HStack {
                Text("\(kind.toString()) Bills").font(.title)
                Spacer()
            }
        
            Table(self.bills, selection: $tableSelected) {
                TableColumn("Name") { bill in
                    Text(bill.name)
                }
                TableColumn("Amount") { bill in
                    Text(bill.amount, format: .currency(code: "USD"))
                }
                TableColumn("Frequency") { bill in
                    Text(bill.period.toString())
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
        }.toolbar() {
            GeneralActionsPanel(on_add: add_bill, on_edit: edit_selected, on_delete: remove_selected)
        }
    }
}

#Preview {
    AllBillsViewEdit(kind: .simple).modelContainer(ModelController.previewContainer)
}

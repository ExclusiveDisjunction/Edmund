//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

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
            
            HStack {
                Button(action: add_bill) {
                    Label("Add", systemImage: "plus")
                }
                
                Button(action: edit_selected) {
                    Label("Edit", systemImage: "pencil")
                }.disabled(tableSelected == nil)
                
                Button(action: remove_selected) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }
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
        }
    }
}

#Preview {
    AllBillsViewEdit(kind: .simple).modelContainer(ModelController.previewContainer)
}

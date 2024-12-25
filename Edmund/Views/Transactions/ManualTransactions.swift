//
//  ManualTransactions.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import SwiftData;
import Foundation;

class ManualTransactionsViewModel : ObservableObject, TransViewBase {
    @Published var adding : [LedgerEntry] = [];
    @Published var account: String = "";
    @Published var err_msg: String? = nil;
    
    func compile_deltas() -> Dictionary<String, Decimal> {
        adding.reduce(into: [:]) { $0[$1.tender + "." + $1.sub_tender] = $1.credit - $1.debit }
    }
    @discardableResult
    func create_transactions() throws(TransactionError) -> [LedgerEntry] {
        guard !self.account.isEmpty else { throw TransactionError(kind: .empty_argument, on: "Tender") }
        
        for item in adding {
            guard item.memo != "" else { throw TransactionError(kind: .empty_argument, on: "Memo")}
            guard item.location != "" else { throw TransactionError(kind: .empty_argument, on: "Location")}
            guard item.category != "" else { throw TransactionError(kind: .empty_argument, on: "Category")}
            guard item.sub_category != "" else { throw TransactionError(kind: .empty_argument, on: "Sub Category")}
            guard item.sub_tender != "" else { throw TransactionError(kind: .empty_argument, on: "Sub Tender")}
            
            item.tender = self.account;
        }
        
        return adding;
    }
    @discardableResult
    func validate() -> Bool {
        do {
            try create_transactions();
            err_msg = nil;
            return true
            
        } catch let e{
            err_msg = e.localizedDescription;
            return false
        }
    }
    func clear() {
        adding = []
        account = ""
        err_msg = nil
    }
}

struct ManualTransactions: View {
    var id: UUID = UUID();

    @ObservedObject var vm: ManualTransactionsViewModel;
    @State private var selected: UUID?;
    
    private func add_trans() {
        vm.adding.append(LedgerEntry(id: UUID(), memo: "", credit: 0.00, debit: 0.00, date: Date.now, added_on: Date.now, location: "", category: "", sub_category: "", tender: "", sub_tender: ""))
    }
    private func remove_trans() {
        if selected == nil { return }
        vm.adding.removeAll(where: { $0.id == selected })
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Manual Transactions").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding([.leading, .trailing], 10).padding(.top, 5)
            
            HStack {
                Text("For Account:")
                TextField("Enter Account Name", text: $vm.account);
            }.padding([.leading, .trailing], 10)
            
            HStack {
                Button(action: {
                    add_trans()
                }) {
                    Label("Add", systemImage: "plus")
                }.help("Add a transaction to the table")
                Button(action: {
                    remove_trans()
                }) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }.disabled(selected == nil).help("Delete the currently selected transaction")
            }.padding(.bottom, 5)
            
            Table($vm.adding, selection: $selected) {
                TableColumn("Memo") { $item in
                    TextField("Description", text: $item.memo)
                }
                TableColumn("Credit") { $item in
                    TextField("Money In", value: $item.credit, format: .currency(code: "USD"))
                }
                TableColumn("Debit") { $item in
                    TextField("Money Out", value: $item.debit, format: .currency(code: "USD"))
                }
                TableColumn("Date") { $item in
                    DatePicker("Date", selection: $item.t_date, displayedComponents: .date).labelsHidden()
                }
                TableColumn("Location") { $item in
                    TextField("Location", text: $item.location)
                }
                TableColumn("Category") { $item in
                    TextField("Category", text: $item.category)
                }
                TableColumn("Sub Category") { $item in
                    TextField("Sub Category", text: $item.sub_category)
                }
                TableColumn("Sub Tender") { $item in
                    TextField("Sub Tender", text: $item.sub_tender)
                }
            }.padding(5).frame(minHeight: 150)
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ManualTransactions(vm: ManualTransactionsViewModel())
}

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
    init(account: Binding<String>? = nil) {
        self.account = account;
    }
    
    @Published var adding : [LedgerEntry] = [];
    @Published var account: Binding<String>?;
    @Published var err_msg: String? = nil;
    @Published var show_account: Bool = true;
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal> {
        adding.reduce(into: [:]) { $0[AccountPair(account: $1.account, sub_account: $1.sub_account)] = $1.credit - $1.debit }
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil; }
        
        return adding;
    }
    func validate() -> Bool {
        let empty_acc: Bool;
        var empty_lines: [Int] = [];
        
        if let acc = account {
            empty_acc = acc.wrappedValue.isEmpty;
            
            for (i, row) in adding.enumerated() {
                if row.memo.isEmpty || row.category.isEmpty || row.category.isEmpty || row.sub_category.isEmpty || row.sub_account.isEmpty {
                        empty_lines.append(i+1);
                }
            }
        }
        else {
            empty_acc = false;
            
            for (i, row) in adding.enumerated() {
                if row.memo.isEmpty || row.category.isEmpty || row.category.isEmpty || row.sub_category.isEmpty || row.account.isEmpty || row.sub_account.isEmpty {
                        empty_lines.append(i+1);
                }
            }
        }
        
        if empty_acc && !empty_lines.isEmpty {
            err_msg = "Account is empty and the following lines are empty: " + empty_lines.map(String.init).joined(separator: ", ");
            return false;
        }
        else if !empty_acc && !empty_lines.isEmpty {
            err_msg = "The following lines are empty: " + empty_lines.map(String.init).joined(separator: ", ");
            return false;
        }
        else if empty_acc && empty_lines.isEmpty {
            err_msg = "Account is empty";
            return false;
        }
        else {
            err_msg = nil;
            return true;
        }
    }
    func clear() {
        adding = []
        if let acc = account {
            acc.wrappedValue = "";
        }
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
                if let acc = vm.account {
                    TableColumn("Account") { $item in
                        TextField("Account", text: acc)
                    }
                }
                else {
                    TableColumn("Account") { $item in
                        TextField("Account", text: $item.account);
                    }
                }
                TableColumn("Sub Account") { $item in
                    TextField("Sub Account", text: $item.sub_account)
                }
            }.padding(5).frame(minHeight: 150)
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    var test_account = "Checking";
    ManualTransactions(vm: ManualTransactionsViewModel(account: Binding<String>(get: {
        test_account
    }, set: { v in
        test_account = v
    })))
}

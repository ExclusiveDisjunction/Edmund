//
//  ManualTransactions.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import SwiftData;
import Foundation;

class ManTransactionLine : Identifiable {
    init(_ entry: LedgerEntry = .init(memo: "", credit: 0, debit: 0, date: Date.now, location: "", category_pair: .init(kind: .category), account_pair: .init(kind: .account))) {
        self.entry = entry;
    }
    
    var id: UUID = UUID();
    var entry: LedgerEntry;
    var selected: Bool = false;
    
    func contains_empty(show_account: Bool) -> Bool {
        entry.memo.isEmpty || entry.category_pair.isEmpty || (show_account ? entry.account_pair.isEmpty : entry.sub_account.isEmpty)
    }
}

@Observable
class ManualTransactionsViewModel : TransViewBase {
    init(show_account: Bool = true) {
        self.show_account = show_account;
        adding.append(.init())
    }
    
    var adding : [ManTransactionLine] = [];
    var show_account: Bool;
    var enable_dates: Bool = true;
    var err_msg: String? = nil;
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        if !validate() { return nil; }
        
        return adding.reduce(into: [:]) { $0[$1.entry.account_pair] = $1.entry.credit - $1.entry.debit };
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil; }
        
        return adding.reduce(into: []) { $0.append($1.entry)};
    }
    func validate() -> Bool {
        let empty_lines: [Int] = adding.enumerated().reduce(into: []) { result, pair in
            if pair.element.contains_empty(show_account: self.show_account) {
                result.append(pair.offset)
            }
        }
        
        if !empty_lines.isEmpty {
            err_msg = "The following lines contain empty fields: " + empty_lines.map(String.init).joined(separator: ", ")
            return false;
        }
        else {
            err_msg = nil;
            return true;
        }
    }
    func clear() {
        adding = []
        err_msg = nil
    }
}

struct ManualTransactions: View {
    @Bindable var vm: ManualTransactionsViewModel;
    
    private func add_trans() {
        vm.adding.append(.init( .init(memo: "", credit: 0.00, debit: 0.00, date: Date.now, location: "", category_pair: NamedPair(kind: .category), account_pair: NamedPair(kind: .account))))
    }
    private func remove_selected() {
        vm.adding.removeAll(where: { $0.selected })
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
                Button(action: add_trans) {
                    Label("Add", systemImage: "plus")
                }.help("Add a transaction to the table")
                Button(action: remove_selected) {
                    Label("Remove Selected", systemImage: "trash").foregroundStyle(.red)
                }.help("Remove all transactions that are currently selected")
            }.padding(.bottom, 5)
            
            Toggle("Enable Dates", isOn: $vm.enable_dates)
            
            ScrollView {
                Grid {
                    GridRow {
                        Text("")
                        Text("Memo")
                        Text("Credit")
                        Text("Debit")
                        Text("Date")
                        Text("Location")
                        Text("Category")
                        if vm.show_account {
                            Text("Account")
                        }
                    }
                    ForEach($vm.adding) { $item in
                        GridRow {
                            Toggle("Selected", isOn: $item.selected).labelsHidden()
                            TextField("Memo", text: $item.entry.memo).frame(minWidth: 120)
                            TextField("Money In", value: $item.entry.credit, format: .currency(code: "USD")).frame(minWidth: 60)
                            TextField("Money Out", value: $item.entry.debit, format: .currency(code: "USD")).frame(minWidth: 60)
                            DatePicker("Date", selection: $item.entry.t_date, displayedComponents: .date).labelsHidden().disabled(!vm.enable_dates)
                            TextField("Location", text: $item.entry.location).frame(minWidth: 100)
                            NamedPairEditor(acc: $item.entry.category_pair).frame(minWidth: 200)
                            NamedPairEditor(acc: $item.entry.account_pair).frame(minWidth: 200)
                        }.disabled(item.selected)
                    }
                }.padding(5)
            }
            
            /*
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
            */
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    var test_account = "Checking";
    ManualTransactions(vm: .init(show_account: true))
}

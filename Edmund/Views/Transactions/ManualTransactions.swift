//
//  ManualTransactions.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import SwiftData;
import Foundation;

@Observable
class ManTransactionLine : Identifiable {
    init(_ entry: LedgerEntry = .init(memo: "", credit: 0, debit: 0, date: Date.now, location: "", category: .init(), account: .init())) {
        self.entry = entry;
    }
    
    var id: UUID = UUID();
    var entry: LedgerEntry;
    var selected: Bool = false;
    
    func contains_empty(show_account: Bool) -> Bool {
        entry.memo.isEmpty || entry.category.isEmpty || (show_account ? entry.account.isEmpty : entry.account.sub_account.isEmpty)
    }
}

struct ManTransLineView : View {
    @Binding var line: ManTransactionLine;
    @Binding var enable_dates: Bool;
    @Binding var show_account: Bool;
    
    var body: some View {
        Toggle("Selected", isOn: $line.selected).labelsHidden()
        TextField("Memo", text: $line.entry.memo).frame(minWidth: 120).disabled(line.selected)
        TextField("Money In", value: $line.entry.credit, format: .currency(code: "USD")).frame(minWidth: 60).disabled(line.selected)
        TextField("Money Out", value: $line.entry.debit, format: .currency(code: "USD")).frame(minWidth: 60).disabled(line.selected)
        DatePicker("Date", selection: $line.entry.date, displayedComponents: .date).labelsHidden().disabled(!enable_dates || line.selected)
        TextField("Location", text: $line.entry.location).frame(minWidth: 100).disabled(line.selected)
        CategoryNameEditor(category: $line.entry.category).frame(minWidth: 200).disabled(line.selected)
        
        if show_account {
            AccountNameEditor(account: $line.entry.account).frame(minWidth: 200).disabled(line.selected)
        }
        else {
            TextField("Sub Account", text: $line.entry.account.sub_account).frame(minWidth: 200).disabled(line.selected)
        }
    }
}

@Observable
class ManualTransactionsVM : TransViewBase {
    init(show_account: Bool = true) {
        self.show_account = show_account;
        adding.append(.init())
    }
    
    var adding : [ManTransactionLine] = [];
    var show_account: Bool;
    var enable_dates: Bool = true;
    var err_msg: String? = nil;
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal>? {
        if !validate() { return nil; }
        
        return adding.reduce(into: [:]) { $0[$1.entry.account] = $1.entry.credit - $1.entry.debit };
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
    @Bindable var vm: ManualTransactionsVM;
    
    private func add_trans() {
        vm.adding.append(.init())
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
                Button(action: {
                    withAnimation {
                        add_trans()
                    }
                }) {
                    Label("Add", systemImage: "plus")
                }.help("Add a transaction to the table")
                Button(action: {
                    withAnimation {
                        remove_selected()
                    }
                }) {
                    Label("Remove Selected", systemImage: "trash").foregroundStyle(.red)
                }.help("Remove all transactions that are currently selected")
            }.padding(.bottom, 5)
            
            Toggle("Enable Dates", isOn: $vm.enable_dates).help("Enable the date field, for manual input. You can disable the date field for quicker inputs if the current date is satisfactory.")
            
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
                        else {
                            Text("Sub Account")
                        }
                    }
                    ForEach($vm.adding) { $item in
                        GridRow {
                            ManTransLineView(line: $item, enable_dates: $vm.enable_dates, show_account: $vm.show_account)
                        }
                    }
                }.padding().background(.background.opacity(0.7))
            }
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ManualTransactions(vm: .init(show_account: true))
}

//
//  Payday.swift
//  Edmund
//
//  Created by Hollan on 12/25/24.
//

import SwiftUI

class PaydayBreakdown : Identifiable {
    init(account: String) {
        self.account = account
    }
    
    var amount: Decimal = 0;
    var account: String;
    var sub_account: String = "";
    var id: UUID = UUID();
}

class PaydayViewModel: ObservableObject, TransViewBase {
    func compile_deltas() -> Dictionary<String, Decimal> {
        if !validate() { return [:] }
        else {
            return breakdowns.reduce(into: [:]) { $0[$1.account + "." + $1.sub_account] = $1.amount };
        }
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil; }
        
        var result: [LedgerEntry] = breakdowns.map({ item in
            LedgerEntry(id: UUID(), memo: sub_account + " to " + item.sub_account, credit: item.amount, debit: 0, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Pay", tender: item.account, sub_tender: item.sub_account)
        });
        result.insert(LedgerEntry(id: UUID(), memo: "Pay", credit: amount, debit: 0, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Pay", tender: account, sub_tender: sub_account), at: 0)
        result.insert(LedgerEntry(id: UUID(), memo: "Pay to " + account, credit: 0, debit: amount, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Pay", tender: account, sub_tender: sub_account), at: 1);
        
        return result;
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
        var empty_lines: [Int] = [];
        
        if account == "" { empty_fields.append("account") }
        if sub_account == "" { empty_fields.append("sub account") }
        
        for (i, d) in breakdowns.enumerated() {
            if d.sub_account.isEmpty || d.account.isEmpty { empty_lines.append(i + 1) }
        }
        
        if empty_fields.isEmpty && empty_lines.isEmpty {
            err_msg = nil;
            return true
        }
        else if !empty_fields.isEmpty && empty_lines.isEmpty {
            err_msg = "The following fields are empty: " + empty_fields.joined(separator: ", ");
            return false;
        }
        else if empty_fields.isEmpty && !empty_lines.isEmpty {
            err_msg = "The following lines contain empty fields: " + empty_lines.map(String.init).joined(separator: ", ");
            return false;
        }
        else {
            err_msg = "The following fields are empty: " + empty_fields.joined(separator: ", ") + " and the following lines contain empty fields: " + empty_lines.map(String.init).joined(separator: ", ")
            
            return false;
        }
    }
    
    func clear() {
        amount = 0
        account = ""
        sub_account = "Pay"
        breakdowns = [];
        err_msg = nil;
    }
    
    var total: Decimal {
        var sum: Decimal = 0;
        breakdowns.forEach { sum += $0.amount }
        
        return sum
    }
    var remaining: Decimal {
        return amount - total
    }
    
    @Published var amount: Decimal = 0;
    @Published var account: String = "";
    @Published var sub_account: String = "Pay";
    @Published var breakdowns: [PaydayBreakdown] = [];
    @Published var err_msg: String? = nil;
}

struct Payday: View {
    @ObservedObject var vm: PaydayViewModel;
    @State private var selected: UUID?;
    
    var body: some View {
        VStack {
            HStack {
                Text("Payday").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            HStack {
                Text("Amount of")
                TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                Text("into")
                TextField("Account", text: $vm.account)
                TextField("Sub Account", text: $vm.sub_account)
            }
            
            HStack {
                Text("Breakdown").italic().bold().padding(.top, 3)
                Spacer()
            }
            
            HStack {
                Button(action: {
                    vm.breakdowns.append(PaydayBreakdown(account: vm.account))
                }) {
                    Label("Add", systemImage: "plus")
                }
                Button(action: {
                    if selected == nil { return }
                    
                    vm.breakdowns.removeAll(where: { $0.id == selected })
                }) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red).disabled(selected == nil)
                }
            }
            
            HStack {
                Text("Current Total: \(vm.total, format: .currency(code: "USD"))")
                Text("Remaining Balance: \(vm.remaining, format: .currency(code: "USD"))")
            }
            
            Table($vm.breakdowns, selection: $selected) {
                TableColumn("Amount") { $item in
                    TextField("Amount", value: $item.amount, format: .currency(code: "USD"))
                }
                TableColumn("Account") { $item in
                    TextField("Account", text: $item.account)
                }
                TableColumn("Sub Account") { $item in
                    TextField("Sub Account", text: $item.sub_account)
                }
            }.frame(minHeight: 170).padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Payday(vm: PaydayViewModel())
}

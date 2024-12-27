//
//  Payday.swift
//  Edmund
//
//  Created by Hollan on 12/25/24.
//

import SwiftUI

enum BreakdownKind {
    case simple;
    case percent;
}
class PaydayBreakdown: Identifiable {
    init(account_name: String, kind: BreakdownKind) {
        self.amount = 0;
        self.acc = AccountPair(account: account_name, sub_account: "");
        self.kind = kind;
    }
    
    var id: UUID = UUID();
    
    var kind: BreakdownKind;
    var amount: Decimal;
    var acc: AccountPair;
}

class PaydayViewModel: ObservableObject, TransViewBase {
    private func compute_balances() -> (Dictionary<AccountPair, Decimal>, Decimal) {
        var total = amount;
        var result: Dictionary<AccountPair, Decimal> = [:];
        
        for item in breakdowns {
            switch item.kind {
            case .simple:
                result[item.acc] = item.amount;
                total -= item.amount;
            case .percent:
                let changed_by = amount * item.amount;
                result[item.acc] = changed_by;
                total -= changed_by;
            }
        }
        
        return (result, total);
    }
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal> {
        if !validate() {
            return [:];
        }
        
        var result = compute_balances();
        result.0[rem_acc] = result.1;
        
        return result.0;
    }
    func create_transactions() -> [LedgerEntry]? {
        let balances = self.compile_deltas();
        
        var result: [LedgerEntry] = balances.map({ (acc, balance) in
            LedgerEntry(id: UUID(), memo: acc.sub_account + " to " + acc.sub_account, credit: balance, debit: 0, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Pay", tender: acc.account, sub_tender: acc.sub_account)
        });
    
        result.insert(LedgerEntry(id: UUID(), memo: "Pay", credit: amount, debit: 0, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Pay", tender: acc.account, sub_tender: acc.sub_account), at: 0)
        result.insert(LedgerEntry(id: UUID(), memo: "Pay to " + acc.account, credit: 0, debit: amount, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Pay", tender: acc.account, sub_tender: acc.sub_account), at: 1);
        
        return result;
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
        var empty_lines: [Int] = [];
        var invalid_lines: [Int] = [];
        
        if acc.account.isEmpty { empty_fields.append("account") }
        if acc.sub_account.isEmpty { empty_fields.append("sub account") }
        if rem_acc.account.isEmpty { empty_fields.append("remander account") }
        if rem_acc.sub_account.isEmpty { empty_fields.append("remander sub account") }
        
        var balance: Decimal = 0.0;
        for (i, d) in breakdowns.enumerated() {
            if d.acc.sub_account.isEmpty || d.acc.account.isEmpty { empty_lines.append(i + 1) }
            
            switch d.kind {
            case .simple:
                balance += d.amount;
            case .percent:
                let changed_by: Decimal = d.amount * amount;
                balance += changed_by;
                
                if d.amount > 1 {
                    invalid_lines.append(i + 1);
                }
            }
            
            if d.kind == .percent && d.amount >= 1 {
                invalid_lines.append(i + 1)
            }
            if d.kind == .simple && d.amount > amount {
                invalid_lines.append(i + 1);
            }
        }
        
        let balance_invalid: Bool = balance > amount;
        
        var messages: [String] = [];
        
        if !empty_fields.isEmpty {
            messages.append("these fields are empty: " + empty_fields.joined(separator: ", "));
        }
        if !empty_lines.isEmpty {
            messages.append("these breakdown(s) contains empty destinations: " + empty_lines.map(String.init).joined(separator: ", "));
        }
        if !invalid_lines.isEmpty {
            messages.append("these breakdown(s) contain invalid percentages: " + invalid_lines.map(String.init).joined(separator: ", "))
        }
        if balance_invalid {
            messages.append("the balance is greater than what is allowed")
        }
        
        if messages.isEmpty {
            err_msg = nil;
            return true;
        }
        else {
            err_msg = "The following items were invalid: " + messages.joined(separator: "; ");
            return false;
        }
    }
    
    func clear() {
        amount = 0
        acc = AccountPair(account: "", sub_account: "Pay");
        rem_acc = AccountPair(account: "", sub_account: "");
        breakdowns = [];
        err_msg = nil;
    }
    
    var total: Decimal {
        let balances = self.compute_balances();
        var sum: Decimal = 0;
        
        balances.0.values.forEach { sum += $0 }
        
        return sum;
    }
    var remaining: Decimal {
        return self.compute_balances().1;
    }
    
    @Published var amount: Decimal = 0;
    @Published var acc: AccountPair = AccountPair(account: "", sub_account: "Pay");
    @Published var rem_acc: AccountPair = AccountPair(account: "", sub_account: "");
    @Published var breakdowns: [PaydayBreakdown] = [];
    @Published var err_msg: String? = nil;
}

struct Payday: View {
    @ObservedObject var vm: PaydayViewModel;
    @State private var selected: UUID?;
    
    private func amount_field(item_kind: BreakdownKind, binding: Binding<PaydayBreakdown>) -> some View {
        switch item_kind {
        case .percent:
            TextField("Percent", value: binding.amount, format: .percent)
        case .simple:
            TextField("Amount", value: binding.amount, format: .currency(code: "USD"))
        }
    }
    
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
                TextField("Account", text: $vm.acc.account)
                TextField("Sub Account", text: $vm.acc.sub_account)
            }
            
            HStack {
                Text("Breakdown").italic().bold().padding(.top, 3)
                Spacer()
            }
            
            HStack {
                Button(action: {
                    vm.breakdowns.append(
                        PaydayBreakdown(account_name: vm.acc.account, kind: .simple)
                    )
                }) {
                    Label("Add Simple", systemImage: "plus")
                }.help("Add a breakdown that takes a specific amount from the pay")
                Button(action: {
                    vm.breakdowns.append(
                        PaydayBreakdown(account_name: vm.acc.account, kind: .percent)
                    )
                }) {
                    Label("Add Percentage", systemImage: "percent")
                }.help("Add a breakdown that takes a percentage of the pay")
                
                Button(action: {
                    if selected == nil { return }
                    
                    vm.breakdowns.removeAll(where: { $0.id == selected })
                }) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red).disabled(selected == nil)
                }.help("")
            }
            
            HStack {
                Text("Current Total: \(vm.total, format: .currency(code: "USD"))")
                Text("Remaining Balance: \(vm.remaining, format: .currency(code: "USD"))")
            }
            
            Table($vm.breakdowns, selection: $selected) {
                TableColumn("Amount") { $item in
                    amount_field(item_kind: item.kind, binding: $item)
                }
                TableColumn("Account") { $item in
                    TextField("Account", text: $item.acc.account)
                }
                TableColumn("Sub Account") { $item in
                    TextField("Sub Account", text: $item.acc.sub_account)
                }
            }.frame(minHeight: 170)
            
            HStack {
                Text("Insert remaining balance into")
                TextField("Account", text: $vm.rem_acc.account);
                TextField("Sub Account", text: $vm.rem_acc.sub_account)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Payday(vm: PaydayViewModel())
}

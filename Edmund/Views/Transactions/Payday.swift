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
@Observable
class PaydayBreakdown: Identifiable {
    init(account_name: String, kind: BreakdownKind) {
        self.amount = 0;
        self.acc = NamedPair(account_name, "", kind: .account);
        self.kind = kind;
    }
    
    var id: UUID = UUID();
    
    var kind: BreakdownKind;
    var amount: Decimal;
    var acc: NamedPair;
}

@Observable
class PaydayViewModel: TransViewBase {
    private func compute_balances() -> (Dictionary<NamedPair, Decimal>, Decimal) {
        var total = amount;
        var result: Dictionary<NamedPair, Decimal> = [:];
        
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
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal> {
        if !validate() {
            return [:];
        }
        
        var result = compute_balances();
        result.0[rem_acc] = result.1;
        
        return result.0;
    }
    func create_transactions() -> [LedgerEntry]? {
        let balances = self.compile_deltas();
        
        //This is all of the breakdowns combined, which are regarded as "Transfer"
        var result: [LedgerEntry] = balances.map({ (acc, balance) in
            LedgerEntry(memo: acc.child + " to " + acc.child, credit: balance, debit: 0, date: Date.now, location: "Bank", category_pair: NamedPair("Account Control", "Transfer", kind: .category), account_pair: acc)
        });
    
        //This is the actual pay coming into the account
        result.insert(LedgerEntry(memo: "Pay", credit: amount, debit: 0, date: Date.now, location: "Bank", category_pair: NamedPair("Account Control", "Pay", kind: .category), account_pair: acc), at: 0)
        
        //This is the transfer out of pay, but into the breakdowns
        result.insert(LedgerEntry(memo: "Pay to " + acc.parent, credit: 0, debit: amount, date: Date.now, location: "Bank", category_pair: NamedPair("Account Control", "Transfer", kind: .category), account_pair: acc), at: 1);
        
        return result;
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
        var empty_lines: [Int] = [];
        var invalid_lines: [Int] = [];
        
        if acc.parent.isEmpty { empty_fields.append("account") }
        if acc.child.isEmpty { empty_fields.append("sub account") }
        if rem_acc.parent.isEmpty { empty_fields.append("remander account") }
        if rem_acc.child.isEmpty { empty_fields.append("remander sub account") }
        
        var balance: Decimal = 0.0;
        for (i, d) in breakdowns.enumerated() {
            if d.acc.child.isEmpty || d.acc.parent.isEmpty { empty_lines.append(i + 1) }
            
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
        acc = NamedPair("", "Pay", kind: .account);
        rem_acc = NamedPair(kind: .account);
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
    
    var amount: Decimal = 0;
    var acc: NamedPair = NamedPair("", "Pay", kind: .account);
    var rem_acc: NamedPair = NamedPair(kind: .account);
    var breakdowns: [PaydayBreakdown] = [];
    var err_msg: String? = nil;
}

struct Payday: View {
    @Bindable var vm: PaydayViewModel;
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
                NamedPairEditor(acc: $vm.acc)
            }
            
            HStack {
                Text("Breakdown").italic().bold().padding(.top, 3)
                Spacer()
            }
            
            HStack {
                Button(action: {
                    vm.breakdowns.append(
                        PaydayBreakdown(account_name: vm.acc.parent, kind: .simple)
                    )
                }) {
                    Label("Add Simple", systemImage: "plus")
                }.help("Add a breakdown that takes a specific amount from the pay")
                Button(action: {
                    vm.breakdowns.append(
                        PaydayBreakdown(account_name: vm.acc.parent, kind: .percent)
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
                    NamedPairEditor(acc: $item.acc)
                }
            }.frame(minHeight: 170)
            
            HStack {
                Text("Insert remaining balance into")
                NamedPairEditor(acc: $vm.rem_acc)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Payday(vm: PaydayViewModel())
}

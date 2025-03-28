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
    init(kind: BreakdownKind) {
        self.amount = 0;
        self.acc = nil;
        self.kind = kind;
    }
    
    var id: UUID = UUID();
    
    var kind: BreakdownKind;
    var amount: Decimal;
    var acc: SubAccount?;
}

@Observable
class PaydayViewModel: TransViewBase {
    private func compute_balances() -> (Dictionary<SubAccount, Decimal>, Decimal) {
        var total = amount;
        var result: Dictionary<SubAccount, Decimal> = [:];
        
        for item in breakdowns {
            guard let acc = item.acc else { continue }
            
            switch item.kind {
            case .simple:
                result[acc] = item.amount;
                total -= item.amount;
            case .percent:
                let changed_by = amount * item.amount;
                result[acc] = changed_by;
                total -= changed_by;
            }
        }
        
        return (result, total);
    }
    private func compute_bal_with_rem() -> Dictionary<SubAccount, Decimal>? {
        guard validate() else { return nil }
        guard let rem_acc = self.rem_acc else { return nil }
    
        var (result, rem) = compute_balances();
        result[rem_acc] = rem;
        
        return result
    }
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        guard let result = compute_bal_with_rem() else { return nil }
        
        return result.reduce(into: [:]) { $0[$1.key.id] = $1.value }
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        guard let balances = compute_bal_with_rem() else { return nil }
        guard let our_acc = self.acc else { return nil }
        
        var result: [LedgerEntry] = balances.map({ (acc, balance) in
                .init(
                    memo: our_acc.name + " to " + acc.name,
                    credit: balance,
                    debit: 0,
                    date: Date.now,
                    location: "Bank",
                    category: cats.account_control.transfer,
                    account: acc)
        });
    
        //This is the actual pay coming into the account
        result.insert(
            .init(
                memo: "Pay",
                credit: amount,
                debit: 0,
                date: Date.now,
                location: "Bank",
                category: cats.account_control.pay,
                account: our_acc
            ),
            at: 0
        )
        
        //This is the transfer out of pay, but into the breakdowns
        result.insert(
            .init(
                memo: "Pay to " + (our_acc.parent_name ?? ""),
                credit: 0,
                debit: amount,
                date: Date.now,
                location: "Bank",
                category: cats.account_control.transfer,
                account: our_acc
            ),
            at: 1
        );
        
        return result;
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
        var empty_lines: [Int] = [];
        var invalid_lines: [Int] = [];
        
        if acc == nil { empty_fields.append("account") }
        if rem_acc == nil { empty_fields.append("remainder account") }
        
        var balance: Decimal = 0.0;
        for (i, d) in breakdowns.enumerated() {
            if d.acc == nil { empty_lines.append(i + 1) }
            
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
        acc = nil;
        rem_acc = nil;
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
    var acc: SubAccount? = nil;
    var rem_acc: SubAccount? = nil
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
                NamedPairPicker<Account>(target: $vm.acc, child_default: "Pay")
            }
            
            HStack {
                Text("Breakdown").italic().bold().padding(.top, 3)
                Spacer()
            }
            
            HStack {
                Button(action: {
                    vm.breakdowns.append(
                        PaydayBreakdown(kind: .simple)
                    )
                }) {
                    Label("Add Simple", systemImage: "plus")
                }.help("Add a breakdown that takes a specific amount from the pay")
                Button(action: {
                    vm.breakdowns.append(
                        PaydayBreakdown(kind: .percent)
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
                TableColumn("Account") { ($item: Binding<PaydayBreakdown>) in
                    NamedPairPicker<Account>(target: $item.acc)
                }
            }.frame(minHeight: 170)
            
            HStack {
                Text("Insert remaining balance into")
                NamedPairPicker<Account>(target: $vm.rem_acc)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Payday(vm: PaydayViewModel())
}

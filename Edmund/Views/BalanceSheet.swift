//
//  BalanceSheet.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI
import SwiftData


class BalanceSheetAccount : Identifiable {
    init(account: String, from: Dictionary<String, (Decimal, Decimal)>) {
        self.account = account;
        
        subs = from.reduce(into: []) { (result, row) in
            result.append(.init(row.key, credits: row.value.0, debits: row.value.1))
        }
        
        self.subs.sort { $0.balance > $1.balance }
    }
    init(account: String, subs: [BalanceSheetBalance]) {
        self.account = account;
        self.subs = subs;
        
        self.subs.sort { $0.balance > $1.balance }
    }
    
    var account: String;
    var subs: [BalanceSheetBalance];
    var balance: Decimal {
        subs.reduce(into: 0) { $0 += $1.balance }
    }
}
class BalanceSheetBalance : Identifiable {
    init(_ sub_account: String, credits: Decimal, debits: Decimal) {
        self.sub_account = sub_account;
        self.credits = credits;
        self.debits = debits;
    }
    
    var sub_account: String;
    var credits: Decimal;
    var debits: Decimal;
    var balance: Decimal {
        credits - debits
    }
}

@Observable
class BalanceSheetVM {
    init() {
        
    }
    init(synthetic: [BalanceSheetAccount]) {
        self.computed = synthetic;
        self.computed.sort { $0.balance > $1.balance }
    }
    
    func computeBalances(trans: [LedgerEntry]) {
        var t_computed: Dictionary<String, Dictionary<String, (Decimal, Decimal)>> = [:];
        
        trans.forEach { t in
            var prev = t_computed[t.account, default: [:]][t.sub_account, default: (0, 0)];
            prev.0 += t.credit;
            prev.1 += t.debit;
            t_computed[t.account, default: [:]][t.sub_account] = prev;
        }
        
        computed = [];
        for (k, v) in t_computed {
            computed.append(.init(account: k, from: v))
        }
        self.computed.sort { $0.balance > $1.balance }
    }

    var computed: [BalanceSheetAccount] = [];
}

struct BalanceSheet: View {
    @Query var transactions: [LedgerEntry];
    @Bindable var vm: BalanceSheetVM;
    
    private func update_balances() {
        vm.computeBalances(trans: transactions);
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Balance Sheet").font(.title)
                Spacer()
            }.padding()
            
            HStack {
                Button(action: update_balances) {
                    Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                }
                Spacer()
            }.padding([.leading, .bottom])
            
            if vm.computed.isEmpty {
                Text("There are no transactions, and therefore no balances").italic().padding()
                Spacer()
            }
            else {
                ScrollView {
                    VStack {
                        ForEach(vm.computed) { (item: BalanceSheetAccount) in
                            VStack {
                                HStack {
                                    Text(item.account).font(.headline)
                                    Text("\(item.balance, format: .currency(code: "USD"))")
                                    Spacer()
                                }.padding([.leading, .trailing, .bottom])
                                Table(item.subs) {
                                    TableColumn("Sub Account") { balance in
                                        Text(balance.sub_account)
                                    }
                                    TableColumn("Credit") { balance in
                                        Text("\(balance.credits, format: .currency(code: "USD"))")
                                    }
                                    TableColumn("Debit") { balance in
                                        Text("\(balance.debits, format: .currency(code: "USD"))")
                                    }
                                    TableColumn("Balance") { balance in
                                        Text("\(balance.balance, format: .currency(code: "USD"))").foregroundStyle(balance.balance < 0 ? .red : .primary)
                                    }
                                }.frame(minHeight: 150)
                            }.padding([.bottom, .top])
                        }
                    }.background(.background.opacity(0.5)).padding()
                }
            }
        }
    }
}

#Preview {
    /*
    BalanceSheet(vm: BalanceSheetVM(synthetic: [
        .init(account: "Checking", subs: [
            .init("DI", credits: 30, debits: 70),
            .init("Credit Card", credits: 40, debits: 10),
            .init("Utilities", credits: 100, debits: 30)
        ]),
        .init(account: "Savings", subs: [
            .init("Hold", credits: 0, debits: 100),
            .init("Main", credits: 1000, debits: 100)
        ])
    ]))
    */
    
    BalanceSheet(vm: BalanceSheetVM())
}

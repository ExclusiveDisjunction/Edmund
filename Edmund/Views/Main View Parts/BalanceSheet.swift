//
//  BalanceSheet.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI
import SwiftData


class BalanceSheetAccount : Identifiable {
    init(account: String, from: Dictionary<String, (Double, Double)>) {
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
    var balance: Double {
        subs.reduce(into: 0) { $0 += $1.balance }
    }
}
class BalanceSheetBalance : Identifiable {
    init(_ sub_account: String, credits: Double, debits: Double) {
        self.sub_account = sub_account;
        self.credits = credits;
        self.debits = debits;
    }
    
    var sub_account: String;
    var credits: Double;
    var debits: Double;
    var balance: Double {
        credits - debits
    }
}

@Observable
class BalanceSheetVM {
    init(_ document: EdmundSQL) {
        self.sql = document
    }
    init(synthetic: [BalanceSheetAccount]) {
        self.sql = EdmundSQL.previewSQL;
        self.computed = synthetic;
        if var computed = self.computed {
            computed.sort { $0.balance > $1.balance }
        }
    }
    
    func computeBalances() {
        var t_computed: Dictionary<String, Dictionary<String, (Double, Double)>> = [:];
        
        if let trans = sql.getTransactions() {
            
            trans.forEach { t in
                let acc_name = t.account.parent.name, sub_acc_name = t.account.name;
                
                var prev = t_computed[acc_name, default: [:]][sub_acc_name, default: (0, 0)];
                prev.0 += t.inner.credit;
                prev.1 += t.inner.debit;
                t_computed[acc_name, default: [:]][sub_acc_name] = prev;
            }
            
            computed = t_computed.reduce(into: []) {
                $0.append(.init(account: $1.key, from: $1.value))
            }
            if var computed = self.computed {
                computed.sort { $0.balance > $1.balance }
            }
        }
        else {
            computed = nil;
        }
    }

    var sql: EdmundSQL;
    var computed: [BalanceSheetAccount]? = nil;
}

struct BalanceSheet: View {
    @Bindable var vm: BalanceSheetVM;
    
    private func update_balances() {
        vm.computeBalances();
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
            
            if let computed = vm.computed {
                if computed.isEmpty {
                    Text("There are no transactions, or a refresh is needed").italic().padding()
                    Spacer()
                }
                else {
                    ScrollView {
                        VStack {
                            ForEach(computed) { (item: BalanceSheetAccount) in
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
                    Spacer()
                }
            }
            else {
                Text("There is no data loaded, please refresh").italic().padding()
                Spacer()
            }
        }.onAppear(perform: update_balances)
    }
}

#Preview {
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
    
    //BalanceSheet(vm: BalanceSheetVM())
}

//
//  BalanceSheet.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI
import SwiftData

struct BalanceResolver {
    static func compileBalances(_ on: [LedgerEntry]) -> Dictionary<UUID, (Decimal, Decimal)> {
        return BalanceResolver.compileBalancesSubAccounts(on).reduce(into: [:]) { $0[$1.key.id] = $1.value }
    }
    static func compileBalancesSubAccounts(_ on: [LedgerEntry]) -> Dictionary<SubAccount, (Decimal, Decimal)> {
        var result: Dictionary<SubAccount, (Decimal, Decimal)> = [:];
        
        for entry in on {
            var temp = result[entry.account, default: (0, 0)];
            temp.0 += entry.credit;
            temp.1 += entry.debit;
            
            result[entry.account] = temp;
        }
        
        return result;
    }
    static func compileBalancesAccounts(_ on: [LedgerEntry]) -> Dictionary<Account, (Decimal, Decimal)> {
        var result: Dictionary<Account, (Decimal, Decimal)> = [:];
        
        for entry in on {
            var temp = result[entry.account.parent, default: (0, 0)];
            temp.0 += entry.credit;
            temp.1 += entry.debit;
            
            result[entry.account.parent] = temp;
        }
        
        return result
    }
    static func uuidToSubAccounts(_ source: [SubAccount], target: Dictionary<UUID, (Decimal, Decimal)>) -> Dictionary<SubAccount, (Decimal, Decimal)> {
        let lookup: Dictionary<UUID, SubAccount> = source.reduce(into: [:]) { $0[$1.id] = $1 }
        
        return target.reduce(into: [:]) { $0[lookup[$1.key, default: SubAccount("ERROR", parent: Account("ERROR"))] ] = $1.value }
    }
    
    static func mergeByDeltas(balances: inout Dictionary<UUID, Decimal>, deltas: Dictionary<UUID, Decimal>) {
        for item in deltas {
            balances[item.key, default: 0] += item.value
        }
    }
    
    static func groupByAccountName(_ on: Dictionary<SubAccount, (Decimal, Decimal)>) -> Dictionary<String, [BalanceSheetBalance]> {
        var result: Dictionary<String, [BalanceSheetBalance]> = [:];
        
        for item in on {
            result[item.key.parent_name, default: []].append( BalanceSheetBalance(item.key.name, credits: item.value.0, debits: item.value.1) )
        }
        
        return result
    }
}

class BalanceSheetAccount : Identifiable {
    init(name: String, subs: [BalanceSheetBalance]) {
        self.name = name;
        self.subs = subs;
        
        self.subs.sort { $0.balance > $1.balance }
    }
    
    var name: String;
    var subs: [BalanceSheetBalance];
    var balance: Decimal {
        subs.reduce(into: 0) { $0 += $1.balance }
    }
}
class BalanceSheetBalance : Identifiable {
    init(_ name: String, credits: Decimal, debits: Decimal) {
        self.name = name
        self.credits = credits
        self.debits = debits
    }
    
    var name: String;
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
        let rawBalances = BalanceResolver.compileBalancesSubAccounts(trans);
        let zipped = BalanceResolver.groupByAccountName(rawBalances);
        
        self.computed = zipped.map { BalanceSheetAccount(name: $0.key, subs: $0.value) }
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
            
            if vm.computed.isEmpty {
                Text("There are no transactions, or this page needs to be refreshed").italic().padding()
                Spacer()
            }
            else {
                ScrollView {
                    VStack {
                        ForEach(vm.computed) { (item: BalanceSheetAccount) in
                            VStack {
                                HStack {
                                    Text(item.name).font(.headline)
                                    Text("\(item.balance, format: .currency(code: "USD"))")
                                    Spacer()
                                }.padding([.leading, .trailing, .bottom])
                                Table(item.subs) {
                                    TableColumn("Sub Account") { balance in
                                        Text(balance.name)
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
        }.onAppear(perform: update_balances)
        .toolbar {
            Button(action: update_balances) {
                Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
            }
        }
        .navigationTitle("Balance Sheet")
        
    }
}

#Preview {
    BalanceSheet(vm: BalanceSheetVM()).modelContainer(ModelController.previewContainer)
}

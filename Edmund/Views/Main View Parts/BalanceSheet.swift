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
            if let account = entry.account {
                var temp = result[account, default: (0, 0)];
                temp.0 += entry.credit;
                temp.1 += entry.debit;
                
                result[account] = temp;
            }
            
        }
        
        return result;
    }
    static func compileBalancesAccounts(_ on: [LedgerEntry]) -> Dictionary<Account, (Decimal, Decimal)> {
        var result: Dictionary<Account, (Decimal, Decimal)> = [:];
        
        for entry in on {
            if let parent = entry.account?.parent {
                var temp = result[parent, default: (0, 0)];
                temp.0 += entry.credit;
                temp.1 += entry.debit;
                
                result[parent] = temp;
            }
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
            result[item.key.parent_name ?? "", default: []].append( BalanceSheetBalance(item.key.name, credits: item.value.0, debits: item.value.1) )
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
    var expanded = true;
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
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
                                    Text(item.name).font(.title2)
                                    Text("\(item.balance, format: .currency(code: "USD"))").foregroundStyle(item.balance < 0 ? .red : .primary).font(.title2)
                                    Spacer()
                                }.padding()
                                
                                if item.expanded {
                                    Grid {
                                        GridRow {
                                            Text("Sub Account").frame(maxWidth: .infinity).font(.headline)
                                            if horizontalSizeClass != .compact {
                                                Text("Credit").frame(maxWidth: .infinity).font(.headline)
                                                Text("Debit").frame(maxWidth: .infinity).font(.headline)
                                            }
                                            Text("Balance").frame(maxWidth: .infinity).font(.headline)
                                        }
                                        Divider()
                                        
                                        ForEach(item.subs) { sub in
                                            GridRow {
                                                Text(sub.name)
                                                if horizontalSizeClass != .compact {
                                                    Text("\(sub.credits, format: .currency(code: "USD"))")
                                                    Text("\(sub.debits, format: .currency(code: "USD"))")
                                                }
                                                Text("\(sub.balance, format: .currency(code: "USD"))").foregroundStyle(sub.balance < 0 ? .red : .primary )
                                            }
                                        }
                                    }
                                }
                                
                                Divider()
                            }
                        }
                    }
                }
            }
        }.onAppear(perform: update_balances)
        .toolbar {
            Button(action: update_balances) {
                Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
            }
        }
        .navigationTitle("Balance Sheet")
        .padding()
        
    }
}

#Preview {
    BalanceSheet(vm: BalanceSheetVM()).modelContainer(Containers.debugContainer)
}

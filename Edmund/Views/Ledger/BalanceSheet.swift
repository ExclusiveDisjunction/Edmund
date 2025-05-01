//
//  BalanceSheet.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI
import SwiftData
import EdmundCore

struct BalanceResolver {
    static func computeAccountBalances(_ on: [Account]) -> Dictionary<Account, (Decimal, Decimal)> {
        var result: [Account: (Decimal, Decimal)] = [:];
        for account in on {
            var credits: Decimal = 0.0
            var debits: Decimal = 0.0
            guard let subAccounts = account.children else { continue }
            
            for subAccount in subAccounts {
                guard let transactions = subAccount.transactions else { continue }
                
                for trans in transactions {
                    credits += trans.credit
                    debits += trans.debit
                }
            }
            
            result[account] = (credits, debits)
        }
        
        return result
    }
    static func computeSubAccountBalances(_ on: [Account]) -> Dictionary<Account, Dictionary<SubAccount, (Decimal, Decimal)>> {
        var result: [Account: [SubAccount: (Decimal, Decimal)]] = [:];
        for account in on {
            var tmpResult: [SubAccount: (Decimal, Decimal)] = [:]
            
            guard let subAccounts = account.children else { continue }
            for subAccount in subAccounts {
                var credits: Decimal = 0
                var debits: Decimal = 0
                guard let transactions = subAccount.transactions else { continue }
                for trans in transactions {
                    credits += trans.credit
                    debits += trans.debit
                }
                
                tmpResult[subAccount] = (credits, debits)
            }
            
            result[account] = tmpResult;
        }
        
        return result
    }
}

@Observable
class AccountBalance : Identifiable {
    init(name: String, credit: Decimal, debit: Decimal) {
        self.id = UUID()
        self.name = name
        self.credit = credit
        self.debit = debit
    }
    
    let id: UUID;
    let name: String;
    let credit: Decimal;
    let debit: Decimal;
    var balance: Decimal {
        credit - debit
    }
}

@Observable
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
@Observable
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
    
    static func computeBalances(acc: [Account]) -> [BalanceSheetAccount] {
        return BalanceResolver.computeSubAccountBalances(acc).map { (account, subBalances) in
            BalanceSheetAccount(name: account.name, subs: subBalances.map { (subAccount, balance) in
                BalanceSheetBalance(subAccount.name, credits: balance.0, debits: balance.1)
            })
        }.sorted(by: { $0.balance > $1.balance } )
    }

    var computed: [BalanceSheetAccount]? = nil;
}

struct BalanceSheet: View {
    private var shouldShowPopoutButton: Bool {
#if os(macOS)
        return true
#else
        if #available(iOS 16.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        return false
#endif
    }
    
    @Query private var accounts: [Account];
    
    @Bindable var vm: BalanceSheetVM;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func update_balances() {
        vm.computed = nil;
    }
    private func compute_balances() -> [BalanceSheetAccount] {
        return BalanceSheetVM.computeBalances(acc: accounts)
    }
    private func expand_all() {
        if let computed = vm.computed {
            withAnimation(.spring()) {
                for element in computed {
                    element.expanded = true
                }
            }
        }
    }
    private func collapse_all() {
        if let computed = vm.computed {
            withAnimation(.spring()) {
                for element in computed {
                    element.expanded = false
                }
            }
        }
    }
    private func popout() {
        openWindow(id: "balanceSheet")
    }
    
    @ViewBuilder
    private func childSection(_ item: BalanceSheetAccount) -> some View {
        if item.subs.isEmpty {
            Text("There are no associated transactions for this account")
                .italic()
        }
        else {
            Grid {
                GridRow {
                    HStack {
                        Text("Sub Account").font(.headline)
                        Spacer()
                    }
                    if horizontalSizeClass != .compact && ledgerStyle != .none {
                        HStack {
                            Spacer()
                            
                            Text(ledgerStyle == .standard ? "Debit" : "Credit").font(.headline)
                        }
                        HStack {
                            Spacer()
                            
                            Text(ledgerStyle == .standard ? "Credit" : "Debit").font(.headline)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Text("Balance").font(.headline)
                    }
                }
                Divider()
                
                ForEach(item.subs) { sub in
                    GridRow {
                        HStack {
                            Text(sub.name)
                            Spacer()
                        }
                        
                        if horizontalSizeClass != .compact && ledgerStyle != .none {
                            HStack {
                                Spacer()
                                Text(sub.credits, format: .currency(code: currencyCode))
                            }
                            
                            HStack {
                                Spacer()
                                Text(sub.debits, format: .currency(code: currencyCode))
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Text(sub.balance, format: .currency(code: currencyCode)).foregroundStyle(sub.balance < 0 ? .red : .primary )
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func accountView(_ item: BalanceSheetAccount) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                item.expanded.toggle()
            }
        }) {
            HStack {
                Label(item.name, systemImage: item.expanded ? "chevron.down" : "chevron.right").font(.title2)
                Text(item.balance, format: .currency(code: currencyCode)).foregroundStyle(item.balance < 0 ? .red : .primary).font(.title2)
                Spacer()
            }.contentShape(Rectangle())
        }.padding().buttonStyle(.borderless)
        
        if item.expanded {
            childSection(item)
        }
        
        Divider()
    }
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: update_balances) {
                Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
            }
        }
        
        ToolbarItem(placement: .secondaryAction) {
            ControlGroup {
                Button(action: collapse_all) {
                    Label("Collapse All", systemImage: "arrow.up.to.line")
                }
                Button(action: expand_all) {
                    Label("Expand All", systemImage: "arrow.down.to.line")
                }
            }
        }
        
        if shouldShowPopoutButton {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: popout) {
                    Label("Open in new Window", systemImage: "rectangle.badge.plus")
                }
            }
        }
    }
    
    var body: some View {
        LoadableView($vm.computed, process: compute_balances, onLoad: { computed in
            VStack {
                if computed.isEmpty {
                    Text("There are no transactions, or this page needs to be refreshed").italic().padding()
                    Spacer()
                }
                else {
                    ScrollView {
                        VStack {
                            ForEach(computed) { item in
                                accountView(item)
                            }
                        }
                    }
                }
            }
        }).toolbar {
            toolbar
        }
        .navigationTitle("Balance Sheet")
        .padding()
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 200)
        #endif
    }
}

#Preview {
    BalanceSheet(vm: BalanceSheetVM())
        .padding()
        .frame(width: 500, height: 400).modelContainer(Containers.debugContainer)
}

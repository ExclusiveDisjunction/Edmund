//
//  BalanceSheet.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI
import SwiftData

struct BalanceSheetWindow : View {
    init(profile: Binding<String?>, vm: BalanceSheetVM = .init()) {
        self._profileName = profile
        self.vm = vm
    }
    @Binding var profileName: String?;
    @Bindable var vm: BalanceSheetVM;
    
    var body: some View {
        BalanceSheet(profile: Binding(
            get: { profileName ?? Containers.defaultContainerName.name },
            set: { profileName = $0 }
        ), isPopout: true, vm: vm)
    }
}

struct BalanceResolver {
    static func computeAccountBalances(_ on: [Account]) -> Dictionary<Account, (Decimal, Decimal)> {
        var result: [Account: (Decimal, Decimal)] = [:];
        for account in on {
            var credits: Decimal = 0.0
            var debits: Decimal = 0.0
            for subAccount in account.children {
                for trans in subAccount.transactions {
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
            for subAccount in account.children {
                var credits: Decimal = 0
                var debits: Decimal = 0
                for trans in subAccount.transactions {
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
    init(synthetic: [BalanceSheetAccount]) {
        self.computed = synthetic;
        self.computed.sort { $0.balance > $1.balance }
    }
    
    func computeBalances(acc: [Account]) {
        self.computed = BalanceResolver.computeSubAccountBalances(acc).map { (account, subBalances) in
            BalanceSheetAccount(name: account.name, subs: subBalances.map { (subAccount, balance) in
                BalanceSheetBalance(subAccount.name, credits: balance.0, debits: balance.1)
            })
        }.sorted(by: { $0.balance > $1.balance } )
    }

    var computed: [BalanceSheetAccount] = [];
}

struct BalanceSheet: View {
    @Binding var profile: String;
    @State var isPopout = false;
    var vm: BalanceSheetVM;
    
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
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func update_balances() {
        vm.computeBalances(acc: accounts)
    }
    private func expand_all() {
        withAnimation(.spring()) {
            for element in vm.computed {
                element.expanded = true
            }
        }
    }
    private func collapse_all() {
        withAnimation(.spring()) {
            for element in vm.computed {
                element.expanded = false
            }
        }
    }
    private func popout() {
        openWindow(id: "balanceSheet", value: profile)
    }
    
    @ViewBuilder
    private func childSection(_ item: BalanceSheetAccount) -> some View {
        Grid {
            GridRow {
                Text("Sub Account").frame(maxWidth: .infinity).font(.headline)
                if horizontalSizeClass != .compact && ledgerStyle != .none {
                    Text(ledgerStyle == .standard ? "Debit" : "Credit").frame(maxWidth: .infinity).font(.headline)
                    Text(ledgerStyle == .standard ? "Credit" : "Debit").frame(maxWidth: .infinity).font(.headline)
                }
                
                Text("Balance").frame(maxWidth: .infinity).font(.headline)
            }
            Divider()
            
            ForEach(item.subs) { sub in
                GridRow {
                    Text(sub.name)
                    if horizontalSizeClass != .compact && ledgerStyle != .none {
                        Text(sub.credits, format: .currency(code: currencyCode))
                        Text(sub.debits, format: .currency(code: currencyCode))
                    }
                    Text(sub.balance, format: .currency(code: currencyCode)).foregroundStyle(sub.balance < 0 ? .red : .primary )
                }
            }
        }
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
                        }
                    }
                }
            }
        }.onAppear(perform: update_balances)
            .toolbar(id: "balanceSheetToolbar") {
                ToolbarItem(id: "refresh", placement: .primaryAction) {
                    Button(action: update_balances) {
                        Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                    }
                }
                
                ToolbarItem(id: "view", placement: .secondaryAction) {
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
                    ToolbarItem(id: "popout", placement: .secondaryAction) {
                        Button(action: popout) {
                            Label("Open in new Window", systemImage: "rectangle.badge.plus")
                        }
                    }
                }
            }
            .navigationTitle(isPopout ? "Balance Sheet for \(profile)" : "Balance Sheet")
            .padding()
            .toolbarRole(.editor)
        
    }
}

#Preview {
    var profile: String = ContainerNames.debug.name
    let bind = Binding(
        get: { profile },
        set: { profile = $0 }
    )
    
    BalanceSheet(profile: bind, vm: BalanceSheetVM()).modelContainer(Containers.debugContainer)
}

//
//  BalanceSheet.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI
import SwiftData
import EdmundCore

/// A top level view to display all accounts, their balances, and then the sub balances within.
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
    
    @State private var computed: [ComplexBalance]? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        computed = nil;
    }
    private func computeBalances() -> [ComplexBalance] {
        var bal = BalanceResolver.computeSubBalances(accounts)
            .intoComplexBalances();
        bal.sortByBalances()
        
        return bal
    }
    private func expandAll() {
        if let computed = computed {
            withAnimation(.spring()) {
                for element in computed {
                    element.expanded = true
                }
            }
        }
    }
    private func collapseAll() {
        if let computed = computed {
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
    
    /// The view for each sub account
    @ViewBuilder
    private func childSection(_ item: ComplexBalance) -> some View {
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
                                Text(sub.credit, format: .currency(code: currencyCode))
                            }
                            
                            HStack {
                                Spacer()
                                Text(sub.debit, format: .currency(code: currencyCode))
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
    
    /// The view for accounts
    @ViewBuilder
    private func accountView(_ item: ComplexBalance) -> some View {
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
            ControlGroup {
                Button(action: collapseAll) {
                    Label("Collapse All", systemImage: "arrow.up.to.line")
                }
                Button(action: expandAll) {
                    Label("Expand All", systemImage: "arrow.down.to.line")
                }
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: refresh) {
                Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
            }
        }
        
        if shouldShowPopoutButton {
            ToolbarItem(placement: .primaryAction) {
                Button(action: popout) {
                    Label("Open in new Window", systemImage: "rectangle.badge.plus")
                }
            }
        }
    }
    
    var body: some View {
        LoadableView($computed, process: computeBalances, onLoad: { computed in
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
    BalanceSheet()
        .frame(width: 500, height: 400).modelContainer(Containers.debugContainer)
}

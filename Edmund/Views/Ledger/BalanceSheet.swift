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
    @Query private var accounts: [Account];
    
    @State private var computed: [DetailedBalance]? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        computed = nil;
    }
    private func computeBalances() -> [DetailedBalance] {
        BalanceResolver.computeSubBalances(accounts)
            .intoDetailedBalances()
            .sortedByBalances()
    }
    
    /// The view for each sub account
    @ViewBuilder
    private func childSection(_ item: DetailedBalance) -> some View {
        if let children = item.children {
            if children.isEmpty {
                Text("There are no associated transactions for this account")
                    .italic()
            }
            else {
                Grid {
                    GridRow {
                        HStack {
                            Text("Sub Account Name").font(.headline)
                            Spacer()
                        }
                        if horizontalSizeClass != .compact {
                            HStack {
                                Spacer()
                                
                                Text(ledgerStyle.displayCredit)
                                    .font(.headline)
                            }
                            HStack {
                                Spacer()
                                
                                Text(ledgerStyle.displayDebit)
                                    .font(.headline)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Text("Balance").font(.headline)
                        }
                    }
                    Divider()
                    
                    ForEach(children, id: \.id) { sub in
                        GridRow {
                            HStack {
                                Text(sub.name)
                                Spacer()
                            }
                            
                            if horizontalSizeClass != .compact {
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
                                Text(sub.balance, format: .currency(code: currencyCode))
                                    .foregroundStyle(sub.balance < 0 ? .red : .primary )
                            }
                        }
                    }
                }
            }
        }
        else {
            Text("internalError")
        }
    }
    
    /// The view for accounts
    @ViewBuilder
    private func accountView(_ item: DetailedBalance) -> some View {
        VStack {
            HStack {
                Text(item.name)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.accent)
                
                Spacer()
                
                Text(item.balance, format: .currency(code: currencyCode))
                    .foregroundStyle(item.balance < 0 ? .red : .primary)
                    .font(.title2)
                
            }
            
            childSection(item)
            
            Divider()
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                }
            }
        }
        .navigationTitle("Balance Sheet")
        .padding()
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 200)
        #endif
    }
}

#Preview {
    DebugContainerView {
        BalanceSheet()
            .frame(width: 500, height: 400)
    }
}

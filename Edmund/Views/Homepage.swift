//
//  Homepage.swift
//  Edmund
//
//  Created by Hollan on 1/1/25.
//

import SwiftUI;
import SwiftData;
import EdmundCore



struct Homepage : View {
    #if os(iOS)
    init(help: Binding<Bool>, settings: Binding<Bool>) {
        
    }
    #else
    init() {
        
    }
    #endif
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    #if os(iOS)
    @Binding private var showHelp: Bool;
    @Binding private var showSettings: Bool;
    #endif
    
    @Query private var accounts: [Account];
    @Query private var bills: [Bill];
    @Query private var utilities: [Utility];
    private var allBills: [any BillBase] {
        bills + utilities
    }
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    @Environment(\.openSettings) private var openSettings;
#endif
    @Environment(\.openWindow) private var openWindow;
    
    @State private var loadedBalances: [AccountBalance]? = nil;
    @State private var loadedBills: [UpcomingBill]? = nil;
    
    private func loadBalances() -> [AccountBalance] {
        let rawBalances = BalanceResolver.computeAccountBalances(accounts);
        let transformed = rawBalances.map { AccountBalance(name: $0.key.name, credit: $0.value.0, debit: $0.value.1) }.sorted(using: KeyPathComparator(\.balance, order: .reverse))
        
        return transformed
    }
    private func loadBills() -> [UpcomingBill] {
        .init()
    }
    
    private func showSettings() {
#if os(macOS)
        openSettings()
#else
        showingSettings = true
#endif
    }
    private func showHelp() {
#if os(macOS)
        openWindow(id: "help")
#else
        if canPopoutWindow {
            openWindow(id: "help")
        }
        else {
            showingHelp = true
        }
#endif
    }
    
    @ViewBuilder
    private var billsView: some View {
        LoadableView($loadedBills, process: loadBills, onLoad: { loaded in
            List(loaded) { bill in
                HStack {
                    Text(bill.name)
                    Spacer()
                    Text(bill.amount, format: .currency(code: currencyCode))
                    Text("on", comment: "$_ on [date]")
                    Text(bill.dueDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
        })
    }
    @ViewBuilder
    private var accountsView: some View {
        LoadableView($loadedBalances, process: loadBalances, onLoad: { balances in
            List(balances) { account in
                HStack {
                    Text(account.name)
                    Spacer()
                    Text(account.balance, format: .currency(code: currencyCode))
                        .foregroundStyle(account.balance < 0 ? .red : .primary)
                }
            }
        })
    }
    
    @ViewBuilder
    private func mainContent(horiz: Bool) -> some View {
        if horiz {
            GeometryReader { geometry in
                VStack {
                    Text("Upcoming Bills").font(.headline)
                    billsView.frame(width: geometry.size.width)
                }
            }
            
            GeometryReader { geometry in
                VStack {
                    Text("Account Balances").font(.headline)
                    accountsView.frame(width: geometry.size.width)
                }
            }
        }
        else {
            billsView.frame(minHeight: 250)
            accountsView.frame(minHeight: 250)
        }
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                VStack(spacing: 10) {
                    mainContent(horiz: false)
                }
            }
            else {
                HStack(spacing: 10) {
                    mainContent(horiz: true)
                }
            }
        }.navigationTitle("Welcome")
            .padding()
            .toolbar {
                Button(action: showSettings) {
                    Image(systemName: "gear")
                }
                
                Button(action: showHelp) {
                    Image(systemName: "questionmark")
                }
            }
    }
}

#Preview {
    Homepage()
}

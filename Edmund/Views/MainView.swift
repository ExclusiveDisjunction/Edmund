//
//  ContentView.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

struct MainView: View {
    @AppStorage("enableTransactions") var enableTransactions: Bool?;
    
    @State private var balance_vm: BalanceSheetVM = .init();
    @State private var accCatvm: AccountsCategoriesVM = .init();
    
#if os(iOS)
    @State private var showingSettings = false;
    @State private var showingHelp = false;
#else
    @Environment(\.openSettings) private var openSettings;
#endif
    
    @Environment(\.openWindow) private var openWindow;
    
    private var canPopoutWindow: Bool {
#if os(macOS)
        return true
#else
        if #available(iOS 16.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        return false
#endif
    }
    
    @ViewBuilder
    private var navLinks: some View {
        List {
            NavigationLink {
                Homepage()
            } label: {
                Text("Home")
            }
            
            if enableTransactions ?? true {
                NavigationLink {
                    LedgerTable()
                } label: {
                    Text("Ledger")
                }
                
                NavigationLink {
                    BalanceSheet(vm: balance_vm)
                } label: {
                    Text("Balance Sheet")
                }
            }
            
            NavigationLink {
                AllBillsViewEdit()
            } label: {
                Text("Bills")
            }
            
            NavigationLink {
                
            } label: {
                Text("Budget")
            }
            
            NavigationLink {
                AccountsCategories(vm: accCatvm)
            } label: {
                Text("Organization")
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund").font(.title).padding(.bottom).backgroundStyle(.background.secondary)
                
                navLinks
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }
        #if os(iOS)
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }.sheet(isPresented: $showingSettings) {
                SettingsView().modelContainer(profiles.global)
            }
        #endif
    }
}

#Preview {
    MainView()
        .modelContainer(Containers.container)
}

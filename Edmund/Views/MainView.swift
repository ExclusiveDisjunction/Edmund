//
//  ContentView.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

enum PageDestinations: LocalizedStringKey, CaseIterable, Identifiable{
    case home = "Homepage",
        ledger = "Ledger",
        balance = "Balance Sheet",
        bills = "Bills",
        budget = "Budget",
        org = "Organization"
    
    var id: Self { self }
    
    static func active(trans: Bool) -> [Self] {
        if trans {
            return Self.allCases
        }
        else {
            return [
                .home,
                .bills,
                .budget,
                .org
            ]
        }
    }
    
    @ViewBuilder
    func view(bal: BalanceSheetVM, org: AccountsCategoriesVM) -> some View {
        switch self {
            case .home: Homepage()
            case .ledger: LedgerTable()
            case .balance: BalanceSheet(vm: bal)
            case .bills: AllBillsViewEdit()
            case .budget: Text("Work in progress").navigationTitle("Budget")
            case .org: AccountsCategories(vm: org)
        }
    }
}

struct MainView: View {
    @AppStorage("enableTransactions") var enableTransactions: Bool = true;
    
    @Bindable private var balance_vm: BalanceSheetVM = .init();
    @Bindable private var accCatvm: AccountsCategoriesVM = .init();
    @State private var page: PageDestinations.ID? = nil;
    @State private var allowedPages = PageDestinations.allCases;
    
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
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund").font(.title).padding(.bottom).backgroundStyle(.background.secondary)
                
                List($allowedPages, selection: $page) { $page in
                    Text(page.rawValue)
                }
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            (page ?? .home).view(bal: balance_vm, org: accCatvm)
        }
    }
}

#Preview {
    MainView()
        .modelContainer(Containers.debugContainer)
}

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
    case home = "Home",
        ledger = "Ledger",
        balance = "Balance Sheet",
        bills = "Bills",
        budget = "Budget",
        org = "Organization"
    
    var id: Self { self }
    
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
    @Bindable private var balance_vm: BalanceSheetVM = .init();
    @Bindable private var accCatvm: AccountsCategoriesVM = .init();
    @State private var page: PageDestinations.ID? = nil;
    @State private var allowedPages = PageDestinations.allCases;
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund")
                    .font(.title)
                    .padding(.bottom)
                    .backgroundStyle(.background.secondary)
                
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

//
//  ContentView.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

enum PageDestinations: LocalizedStringKey, Identifiable {
    case home = "Home",
         ledger = "Ledger",
         balance = "Balance Sheet",
         bills = "Bills",
         budget = "Budget",
         
         org = "Organization",
         accounts = "Accounts",
         categories = "Categories",
         
         pay = "Pay",
         paychecks = "Paychecks",
         jobs = "Jobs",
         taxes = "Taxes"
    
    static var topLevel: [Self] {
        [
            .home,
            .ledger,
            .bills,
            .budget,
            .org,
            .pay
        ]
    }
    var children: [Self]? {
        switch self {
            case .org: [.accounts, .categories]
            case .pay: [.paychecks, .jobs, .taxes]
            default: nil
        }
    }
    
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
            default: Text("Work in progress").navigationTitle(self.rawValue)
        }
    }
}

struct MainView: View {
    @Bindable private var balance_vm: BalanceSheetVM = .init();
    @Bindable private var accCatvm: AccountsCategoriesVM = .init();
    @State private var page: PageDestinations.ID? = nil;
    @State private var allowedPages = PageDestinations.topLevel;
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund")
                    .font(.title)
                    .padding(.bottom)
                    .backgroundStyle(.background.secondary)
                
                List(allowedPages, children: \.children, selection: $page) { page in
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

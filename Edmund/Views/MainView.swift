//
//  MainView.swift
//  Edmund
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

/// The homepage elements that are presented to the user.
enum PageDestinations: LocalizedStringKey, Identifiable {
    case home = "Home",
         ledger = "Ledger",
         balance = "Balance Sheet",
         bills = "Bills",
         budget = "Budget",
         
         org = "Organization",
         accounts = "Accounts",
         credit = "Credit Card Helper",
         audit = "Balance Verifier",
         categories = "Categories",
         
         pay = "Pay",
         paychecks = "Paychecks",
         jobs = "Jobs",
         taxes = "Taxes"
    
    /// The top level options for the main page.
    static var topLevel: [Self] {
        [
            .home,
            .ledger,
            .balance,
            .bills,
            .budget,
            .jobs,
            .org
            //.pay
        ]
    }
    /// The children of a specific top level element. This is `nil` for all other elements.
    var children: [Self]? {
        switch self {
            case .org: [.accounts, .categories, .credit, .audit ]
            case .pay: [.paychecks, .jobs ] //.taxes
            default: nil
        }
    }
    
    var id: Self { self }
    
    var key: String {
        switch self {
            case .home: "homepage"
                
            case .ledger: "ledger"
            case .balance: "balanceSheet"
                
            case .bills: "bills"
                
            case .org: "organization"
            case .accounts: "accounts"
            case .categories: "categories"
            case .credit: "creditHelper"
            case .audit: "auditHelper"
                
            case .jobs: "jobs"
            case .budget: "budget"
            case .pay: "pay"
            case .paychecks: "paychecks"
            case .taxes: "taxes"
        }
    }
    
    /// The specified view used to store the data.
    @ViewBuilder
    var view : some View {
        switch self {
            case .home: Homepage()
                
            case .ledger: LedgerTable()
            case .balance: BalanceSheet()
                
            case .bills: AllBillsViewEdit()
                
            case .org: OrganizationHome()
            case .accounts: AccountsIE()
            case .categories: CategoriesIE()
            case .credit: CreditCardHelper()
            case .audit: BalanceVerifier()
                
            case .jobs: AllJobsViewEdit()
            default: Text("Work in progress").navigationTitle(self.rawValue)
        }
    }
}

struct MainView: View {
    @State private var page: PageDestinations.ID? = nil;
    @State private var allowedPages = PageDestinations.topLevel;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    private static let allowPopouts: Bool = {
#if os(macOS)
        true
#else
        if #available(iOS 16.0, *) { UIDevice.current.userInterfaceIdiom == .pad } 
        else { false }
#endif
    }()
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund")
                    .font(.title)
                    .padding(.bottom)
                    .backgroundStyle(.background.secondary)
                
                List(allowedPages, children: \.children, selection: $page) { page in
                    if Self.allowPopouts {
                        Text(page.rawValue)
                            .contextMenu {
                                Button("Open in new Window", action: {
                                    openWindow(id: page.key)
                                })
                            }
                    }
                    else {
                        Text(page.rawValue)
                    }
                }
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            (page ?? .home).view
                .frame(minWidth: horizontalSizeClass == .compact ? 0 : 500, minHeight: 400)
        }
    }
}

#Preview {
    MainView()
        .modelContainer(Containers.debugContainer)
}

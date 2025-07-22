//
//  MainView.swift
//  Edmund
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

struct PageDestinationWrapper : Identifiable {
    init(name: String, content: [PageDestinations]) {
        self.id = name
        self.name = .init(stringLiteral: name)
        self.content = content
    }
    
    let id: String;
    let name: LocalizedStringKey;
    let content: [PageDestinations];
}

/// The homepage elements that are presented to the user.
enum PageDestinations: LocalizedStringKey, Identifiable {
    case home = "Home"
    
    case ledger = "Ledger"
    case balance = "Balance Sheet"
    case credit = "Credit Card Audit"
    case audit = "Audits"
    
    case bills = "Bills"
    
    case jobs = "Jobs"
    case incomeDivider = "Income Divider"
    case budget = "Budget"
    
    case accounts = "Accounts"
    case categories = "Categories"
    
    //case pay = "Pay"
    //case paychecks = "Paychecks"
    //case taxes = "Taxes"
    
    static var groups: [PageDestinationWrapper] {
        [
            .init(name: "Ledger", content: [
                .ledger,
                .balance,
                .audit,
                .credit
            ]),
            .init(name: "Bills", content: [
                .bills
            ]),
            .init(name: "Budgeting & Pay", content: [
                .incomeDivider,
                .jobs,
            ]),
            .init(name: "Organization", content: [
                .accounts,
                .categories
            ])
        ]
    }
    
    var id: Self { self }
    
    var key: String {
        switch self {
            case .home: "homepage"
                
            case .ledger: "ledger"
            case .balance: "balanceSheet"
            case .credit: "creditHelper"
            case .audit: "auditHelper"
                
            case .bills: "bills"
                
            case .jobs: "jobs"
            case .incomeDivider: "incomeDivider"
            case .budget: "budget"
                
            case .accounts: "accounts"
            case .categories: "categories"
           
            //case .pay: "pay"
            //case .paychecks: "paychecks"
            //case .taxes: "taxes"
        }
    }
    
    /// The specified view used to store the data.
    @MainActor
    @ViewBuilder
    var view : some View {
        switch self {
            case .home: Homepage()
                
            case .ledger: LedgerTable()
            case .balance: BalanceSheet()
                
            case .incomeDivider: AllBudgetsInspect()
                
            case .bills: AllBillsViewEdit()
                
            case .accounts: AccountsIE()
            case .categories: CategoriesIE()
            case .credit: CreditCardHelper()
            case .audit: BalanceVerifier()
                
            case .jobs: AllJobsViewEdit()
            default: Text("Work in progress").navigationTitle(self.rawValue)
        }
    }
}

fileprivate struct PageDestinationsKey : FocusedValueKey {
    typealias Value = Binding<PageDestinations?>;
}
extension FocusedValues {
    var currentPage: Binding<PageDestinations?>? {
        get { self[PageDestinationsKey.self] }
        set { self[PageDestinationsKey.self] = newValue }
    }
}

struct MainView: View {
    @State private var page: PageDestinations.ID? = .home;
    
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
    
    @ViewBuilder
    private func textFor(_ page: PageDestinations) -> some View {
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
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund")
                    .font(.title)
                    .padding(.bottom)
                    .backgroundStyle(.background.secondary)
                
                List(selection: $page) {
                    Text(PageDestinations.home.rawValue).id(PageDestinations.home)
                    
                    ForEach(PageDestinations.groups) { group in
                        Section(group.name) {
                            ForEach(group.content) {
                                textFor($0)
                            }
                        }
                    }
                }
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            (page ?? .home).view
                .frame(minWidth: horizontalSizeClass == .compact ? 0 : 500, minHeight: 400)
        }.navigationSplitViewStyle(.prominentDetail)
            .focusedValue(\.currentPage, $page)
    }
}

#Preview {
    DebugContainerView {
        MainView()
    }
}

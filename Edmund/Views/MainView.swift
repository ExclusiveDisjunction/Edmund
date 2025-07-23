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
    case audit = "Auditor"
    
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
                .audit
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
                
            case .incomeDivider: AllIncomeDivisionsIE()
                
            case .bills: AllBillsViewEdit()
                
            case .accounts: AccountsIE()
            case .categories: CategoriesIE()
            case .audit: Auditor()
                
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
fileprivate struct LockedPagesKey : EnvironmentKey {
    typealias Value = Binding<Bool>;
    static var defaultValue: Binding<Bool> {
        .constant(false)
    }
}
public extension EnvironmentValues {
    var pagesLocked: Binding<Bool> {
        get { self[LockedPagesKey.self] }
        set { self[LockedPagesKey.self] = newValue }
    }
}

struct MainView: View {
    @State private var page: PageDestinations.ID? = .home;
    @State private var locked: Bool = false;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    private static let allowPopouts: Bool = {
#if os(macOS)
        true
#else
        if #available(iOS 16.0, *) { UIDevice.current.userInterfaceIdiom == .pad } 
        else { false }
#endif
    }()
    
    struct PageContent : View {
        let page: PageDestinations;
        
        @Environment(\.openWindow) private var openWindow;
        @Environment(\.isEnabled) private var isEnabled;
        
        @ViewBuilder
        var text: some View {
            if MainView.allowPopouts {
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
            text
                .opacity(isEnabled ? 1.0 : 0.7)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund")
                    .font(.title)
                    .padding(.bottom)
                    .backgroundStyle(.background.secondary)
                
                if locked {
                    Text("Please finish editing & save to change the page")
                        .italic()
                        .multilineTextAlignment(.center)
                }
                
                List(selection: $page) {
                    Text(PageDestinations.home.rawValue).id(PageDestinations.home)
                        .disabled(locked)
                    
                    ForEach(PageDestinations.groups) { group in
                        Section(group.name) {
                            ForEach(group.content) {
                                PageContent(page: $0)
                            }
                        }
                    }
                }.disabled(locked)
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            (page ?? .home).view
                .frame(minWidth: horizontalSizeClass == .compact ? 0 : 500, minHeight: 400)
                .environment(\.pagesLocked, $locked)
        }.navigationSplitViewStyle(.prominentDetail)
            .focusedValue(\.currentPage, $page)
    }
}

#Preview {
    DebugContainerView {
        MainView()
    }
}

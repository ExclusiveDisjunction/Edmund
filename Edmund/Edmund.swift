//
//  Edmund.swift
//  Edmund
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct LoadedApp {
    public let container: ModelContainer;
    public let unique: UniqueEngine;
    public let categories: CategoriesContext;
}

public enum AppLoadErrorKind : Sendable {
    case modelContainer
    case unique
    case categories
}
public struct AppLoadError : Error, Sendable {
    public let with: AppLoadErrorKind;
    public let message: String;
}
public enum AppState {
    case error(AppLoadError)
    case loading
    case loaded(LoadedApp)
}

@Observable
public class AppLoader {
    @MainActor
    public init() {
        Task {
            await load()
        }
    }
    
    public var state: AppState = .loading
    
    @MainActor
    public func load() async {
        let container: ModelContainer;
        let uniqueContext: UniqueContext;
        let unique: UniqueEngine;
        let categories: CategoriesContext;
        
        do {
#if DEBUG
            container = try Containers.debugContainer()
#else
            container = try Containers.mainContainer()
#endif
        }
        catch let e {
            withAnimation {
                self.state = .error(.init(with: .modelContainer, message: e.localizedDescription))
            }
            return;
        }
        
        do {
            uniqueContext = try UniqueContext(container.mainContext)
        }
        catch let e {
            withAnimation {
                self.state = .error(.init(with: .unique, message: e.localizedDescription))
            }
            return;
        }
        
        unique = UniqueEngine(uniqueContext)
        
        do {
            categories = try CategoriesContext(container.mainContext)
        }
        catch let e {
            withAnimation {
                self.state = .error(.init(with: .categories, message: e.localizedDescription))
            }
            return;
        }
        
        let loaded = LoadedApp(container: container, unique: unique, categories: categories)
        withAnimation {
            self.state = .loaded(loaded)
        }
    }
}

struct AppErrorView : View {
    let error: AppLoadError;
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.shield.fill")
                .resizable()
                .scaledToFit()
            Text("Oops!")
                .font(.title)
            
            Text("Edmund has hit a snag while loading, and cannot access your data.")
            Text("Please report this issue.")
            
            Divider()
            
            Grid {
                GridRow {
                    Text("Error Kind:")
                    
                    switch error.with {
                        case .categories: Text("The categories context cannot be loaded.")
                        case .modelContainer: Text("The app's model container could not be loaded.")
                        case .unique: Text("The unique engine could not be loaded.")
                    }
                }
                
                GridRow {
                    Text("Error Message:")
                    
                    Text(error.message)
                }
            }
        }
    }
}

struct AppWindowGate<Content> : View where Content: View {
    var loader: AppLoader;
    let content: () -> Content;
    
    @AppStorage("themeMode") private var themeMode: ThemeMode?;
    
    private var colorScheme: ColorScheme? {
        switch themeMode {
            case .light: return .light
            case .dark: return .dark
            default: return nil
        }
    }
    
    var body: some View {
        switch loader.state {
            case .loading: VStack {
                Text("Please wait while Edmund loads")
                ProgressView()
                    .progressViewStyle(.linear)
            }
                    .preferredColorScheme(colorScheme)
                    .padding()
            case .error(let e): AppErrorView(error: e)
                    .preferredColorScheme(colorScheme)
            case .loaded(let a): self.content()
                    .preferredColorScheme(colorScheme)
                    .environment(\.categoriesContext, a.categories)
                    .environment(\.uniqueEngine, a.unique)
                    .modelContainer(a.container)
                                    
        }
    }
}

@main
struct EdmundApp: App {
    init() {
        self.loader = .init()
         
        /*
#if os(iOS)
        registerBackgroundTasks()
#elseif os(macOS)
        refreshWidget()
#endif
         */
    }
    
    var loader: AppLoader;
    
    @AppStorage("themeMode") private var themeMode: ThemeMode?;
    
    private var colorScheme: ColorScheme? {
        switch themeMode {
            case .light: return .light
            case .dark: return .dark
            default: return nil
        }
    }
    

    var body: some Scene {
        WindowGroup {
            AppWindowGate(loader: loader) {
                MainView()
            }
        }.commands {
            GeneralCommands()
        }
        
        WindowGroup(PageDestinations.home.rawValue, id: PageDestinations.home.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    Homepage()
                }
            }
        }
        
        WindowGroup(PageDestinations.ledger.rawValue, id: PageDestinations.ledger.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    LedgerTable()
                }
            }
        }
        
        WindowGroup(PageDestinations.balance.rawValue, id: PageDestinations.balance.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    BalanceSheet()
                }
            }
        }
        
        WindowGroup(PageDestinations.bills.rawValue, id: PageDestinations.bills.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AllBillsViewEdit()
                }
            }
        }
        
        WindowGroup(PageDestinations.budget.rawValue, id: PageDestinations.budget.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AllBudgetsInspect()
                }
            }
        }
        
        WindowGroup(PageDestinations.org.rawValue, id: PageDestinations.org.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    OrganizationHome()
                }
            }
        }
        
        WindowGroup(PageDestinations.accounts.rawValue, id: PageDestinations.accounts.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AccountsIE()
                }
            }
        }
        
        WindowGroup(PageDestinations.categories.rawValue, id: PageDestinations.categories.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    CategoriesIE()
                }
            }
        }
        
        WindowGroup(PageDestinations.credit.rawValue, id: PageDestinations.credit.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    CreditCardHelper()
                }
            }
        }
        
        WindowGroup(PageDestinations.audit.rawValue, id: PageDestinations.audit.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    BalanceVerifier()
                }
            }
        }
        
        WindowGroup(PageDestinations.jobs.rawValue, id: PageDestinations.jobs.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AllJobsViewEdit()
                }
            }
        }
        
        WindowGroup("Transaction Editor", id: "transactionEditor", for: TransactionKind.self) { kind in
            AppWindowGate(loader: loader) {
                TransactionsEditor(kind: kind.wrappedValue ?? .simple)
            }
        }
        
        #if os(macOS)
        WindowGroup("Expired Bills", id: "expiredBills") {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AllExpiredBillsVE()
                }
            }
        }
        
        Window("About", id: "about") {
            AboutView()
                .preferredColorScheme(colorScheme)
        }
        
        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
        #endif
        
        WindowGroup("Help", id: "help") {
            HelpView()
                .preferredColorScheme(colorScheme)
        }
    }
}

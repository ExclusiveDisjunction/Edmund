//
//  AppLoader.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/5/25.
//

import EdmundCore
import SwiftData
import SwiftUI
import Observation
import os

public struct LoadedAppContext : @unchecked Sendable {
    public let container: Container;
    public let categories: CategoriesContext;
    public let unique: UniqueEngine;
    public let help: HelpEngine;
    public let logger: LoggerSystem;
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
    case loaded(LoadedAppContext)
}

@MainActor
@Observable
public class AppLoadingState {
    public var state: AppState = .loading;
}

public actor AppLoaderEngine {
    public init(unique: UniqueEngine, help: HelpEngine, log: LoggerSystem) {
        self.loaded = nil;
        self.unique = unique
        self.help = help
        self.loadHelpTask = nil;
        self.log = log
    }
    
    private let log: LoggerSystem;
    public var loaded: LoadedAppContext?;
    public var unique: UniqueEngine;
    public var help: HelpEngine;
    public var loadHelpTask: Task<Void, Never>?;
    
    public func reset() async {
        self.loaded = nil;
        await self.unique.reset()
        await self.help.reset()
    }
    
    @MainActor
    private static func getModelContext(state: AppLoadingState) async -> Container? {
        do {
#if DEBUG
            return try Containers.debugContainer()
#else
            return try Containers.mainContainer()
#endif
        }
        catch let e {
            state.state = .error(
                AppLoadError(
                    with: .modelContainer,
                    message: "\(e)"
                )
            )
            
            return nil
        }
    }
    
    @MainActor
    private static func getUniqueContext(state: AppLoadingState, context: ModelContext) -> UniqueContext? {
        do {
            return try UniqueContext(context)
        }
        catch let e {
            state.state = .error(
                AppLoadError(
                    with: .unique,
                    message: "\(e)"
                )
            )
            
            return nil
        }
    }
    
    @MainActor
    private static func getCategories(state: AppLoadingState, context: ModelContext) -> CategoriesContext? {
        do {
            return try CategoriesContext(context)
        }
        catch let e{
            state.state = .error(
                AppLoadError(
                    with: .categories,
                    message: "\(e)"
                )
            )
            
            return nil
        }
    }
    
    private func setLoaded(_ data: LoadedAppContext) {
        self.loaded = data
    }
    
    @MainActor
    private func getAppContext(state: AppLoadingState) async -> LoadedAppContext? {
        log.app.info("Obtaining model container")
        guard let container = await Self.getModelContext(state: state) else {
            return nil;
        }
        
        log.app.info("Obtaining unique context")
        guard let uniqueContext = Self.getUniqueContext(state: state, context: container.context) else {
            return nil
        }
        
        log.app.info("Obtaining categories context")
        guard let categories = Self.getCategories(state: state, context: container.context) else {
            return nil
        }
        
        do {
            try await unique.fill(uniqueContext)
        }
        catch let e {
            state.state = .error(AppLoadError(with: .unique, message: e.localizedDescription))
        }
        
        let unique = await self.unique;
        let help   = await self.help;
        
        log.app.info("App load context is complete.")
        
        return LoadedAppContext(container: container, categories: categories, unique: unique, help: help, logger: log)
    }

    public func loadApp(state: AppLoadingState) async {
        await MainActor.run {
            state.state = .loading
        }
        
        log.app.info("Begining app loading process")
        if let loaded = self.loaded {
            log.app.info("App was previously loaded, keeping that state.")
            await MainActor.run {
                state.state = .loaded(loaded)
            }
            return;
        }
        
        //Reset the unique and help engines, just in case
        await help.reset()
        await unique.reset()
        self.loadHelpTask = Task {
            log.app.info("Instructing help engine to walk it's files.")
            await help.walkDirectory()
        }

        self.loaded = await self.getAppContext(state: state)
        if let loaded = self.loaded {
            log.app.info("The app was loaded sucessfully.")
            await MainActor.run {
                state.state = .loaded(loaded)
            }
        }
        else {
            log.app.error("The app could not be loaded properly.")
        }
    }
}

fileprivate struct AppLoaderEngineKey : EnvironmentKey {
    typealias Value = AppLoaderEngine?
    
    static var defaultValue: AppLoaderEngine? {
        nil
    }
}
public extension EnvironmentValues {
    var appLoader: AppLoaderEngine? {
        get { self[AppLoaderEngineKey.self] }
        set { self[AppLoaderEngineKey.self] = newValue }
    }
}

struct AppWindowGate<Content> : View where Content: View {
    init(appLoader: AppLoaderEngine, state: AppLoadingState, @ViewBuilder content: @escaping () -> Content) {
        self.appLoader = appLoader
        self.state = state
        self.content = content
    }
    var appLoader: AppLoaderEngine;
    var state: AppLoadingState;
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
        switch state.state {
            case .loading:
                VStack {
                    Text("Please wait while Edmund loads")
                    ProgressView()
                        .progressViewStyle(.linear)
                }.preferredColorScheme(colorScheme)
                    .padding()
                
            case .error(let e):
                AppErrorView(error: e, state: state)
                    .preferredColorScheme(colorScheme)
                    .environment(\.appLoader, appLoader)
                
            case .loaded(let a):
                self.content()
                    .preferredColorScheme(colorScheme)
                    .environment(\.categoriesContext, a.categories)
                    .environment(\.uniqueEngine, a.unique)
                    .environment(\.helpEngine, a.help)
                    .environment(\.modelContext, a.container.context)
                    .environment(\.loggerSystem, a.logger)
                
        }
    }
}


//
//  AppLoader.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/5/25.
//

import EdmundCore
import EdmundWidgetCore
import SwiftData
import SwiftUI
import Observation

public struct LoadedAppContext : @unchecked Sendable {
    public let container: ContainerBundle;
    public let categories: CategoriesContext;
    public let unique: UniqueEngine;
    public let help: HelpEngine;
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
    public init(unique: UniqueEngine, help: HelpEngine) {
        self.loaded = nil;
        self.unique = unique
        self.help = help
        self.loadHelpTask = nil;
    }
    
    public var loaded: LoadedAppContext?;
    public var unique: UniqueEngine;
    public var help: HelpEngine;
    public var loadHelpTask: Task<Void, Never>?;
    
    @MainActor
    private static func getModelContext(state: AppLoadingState) async -> ContainerBundle? {
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

    public func loadApp(state: AppLoadingState) async {
        await MainActor.run {
            state.state = .loading
        }
        //Reset the unique and help engines, just in case
        await help.reset()
        await unique.reset()
        
        if let loaded = self.loaded {
            await MainActor.run {
                state.state = .loaded(loaded)
            }
        }
        
        self.loadHelpTask = Task {
            await help.walkDirectory()
        }

        let context: LoadedAppContext? = await Task { @MainActor in
            guard let container = await Self.getModelContext(state: state) else {
                return nil
            }
            
            guard let uniqueContext = Self.getUniqueContext(state: state, context: container.context) else {
                return nil
            }
            
            guard let categories = Self.getCategories(state: state, context: container.context) else {
                return nil
            }
            
            await unique.fill(uniqueContext)
            
            return await LoadedAppContext(container: container, categories: categories, unique: self.unique, help: self.help)
        }.value
        
        self.loaded = context
    }
}

struct AppWindowGate<Content> : View where Content: View {
    init(state: AppLoadingState, @ViewBuilder content: @escaping () -> Content) {
        self.state = state
        self.content = content
    }
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
                AppErrorView(error: e)
                    .preferredColorScheme(colorScheme)
                
            case .loaded(let a):
                self.content()
                    .preferredColorScheme(colorScheme)
                    .environment(\.categoriesContext, a.categories)
                    .environment(\.uniqueEngine, a.unique)
                    .environment(\.helpEngine, a.help)
                    .environment(\.modelContext, a.container.context)
                
        }
    }
}

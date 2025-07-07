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

private struct AppWarningsKey : EnvironmentKey {
    typealias Value = [String]?;
    static var defaultValue: [String]? { nil }
}
public extension EnvironmentValues {
    var appWarnings: [String]? {
        get { self[AppWarningsKey.self] }
        set { self[AppWarningsKey.self] = [] }
    }
}

public struct LoadedApp {
    public let container: ContainerBundle;
    public let unique: UniqueEngine;
    public let categories: CategoriesContext;
    public let warnings: [String];
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
    
    public var state: AppState = .loading;
    
    @MainActor
    public func load() async {
        let container: ContainerBundle;
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
                self.state = .error(.init(with: .modelContainer, message: "\(e)"))
            }
            return;
        }
        
        print("does the context have an undo manager? \(container.context.undoManager != nil)")
        
        do {
            uniqueContext = try UniqueContext(container.context)
        }
        catch let e {
            withAnimation {
                self.state = .error(.init(with: .unique, message: "\(e)"))
            }
            return;
        }
        
        unique = UniqueEngine(uniqueContext)
        
        do {
            categories = try CategoriesContext(container.context)
        }
        catch let e {
            withAnimation {
                self.state = .error(.init(with: .categories, message: "\(e)"))
            }
            return;
        }
        
        var warning: [String] = []
        
        if let provider: WidgetDataProvider = .init() {
            do {
                try await provider.append(data: UpcomingBillsWidgetManager(context: container.context))
                try await provider.prepareWidget()
            }
            catch let e {
                let message = "Unable to save the upcoming bills. \(e)";
                print(message);
                warning.append(message)
            }
        }
        
        let loaded = LoadedApp(container: container, unique: unique, categories: categories, warnings: warning)
        withAnimation {
            self.state = .loaded(loaded)
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
                    .environment(\.appWarnings, a.warnings)
                    .environment(\.modelContext, a.container.context)
                
        }
    }
}

//
//  ui_demoApp.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

@main
struct EdmundApp: App {
    init() {
        let globalContainer = Containers.globalContainer
        self.globalContainer = globalContainer
        
        self.defaultContainer = Containers.defaultContainer
        
        var startingProfiles: [Profile];
        #if DEBUG
        startingProfiles = [Profile("Debug"), Profile("Personal")]
        #else
        startingProfiles = [Profile("Personal")]
        #endif
    
        let foundProfiles = (try? globalContainer.mainContext.fetch(FetchDescriptor<Profile>())) ?? [];
        startingProfiles.append(contentsOf: foundProfiles)
        
        self.profiles = startingProfiles
    }
    
    var defaultContainer: (ModelContainer, ContainerNames);
    var globalContainer: ModelContainer;
    @State private var profiles: [Profile];
    
    @AppStorage("themeMode") private var themeMode: ThemeMode?;
    
    var colorScheme: ColorScheme? {
        switch themeMode {
            case .light: return .light
            case .dark: return .dark
            default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView(current: defaultContainer, global: globalContainer, profiles: $profiles).preferredColorScheme(colorScheme)
        }.commands {
            GeneralCommands()
        }
        
        WindowGroup("Ledger", id: "ledger", for: Profile.ID.self ) { profile in
            if let r_profile = profile.wrappedValue {
                if let resolvedProfile = profiles.first(where: {$0.name == r_profile } ), let container = try? Containers.getNamedContainer(resolvedProfile.name) {
                    NavigationStack {
                        LedgerWindow(profile: profile).modelContainer(container)
                    }
                } else {
                    Text("Was not able to resolve profile").italic().font(.title2)
                }
            }
            else {
                NavigationStack {
                    LedgerWindow(profile: profile).modelContainer(Containers.defaultContainer.0)
                }
            }
        }
        
        WindowGroup("Balance Sheet", id: "balanceSheet", for: Profile.ID.self ) { profile in
            if let r_profile = profile.wrappedValue {
                if let resolvedProfile = profiles.first(where: {$0.name == r_profile } ), let container = try? Containers.getNamedContainer(resolvedProfile.name) {
                    NavigationStack {
                        BalanceSheetWindow(profile: profile).modelContainer(container)
                    }
                } else {
                    Text("Was not able to resolve profile").italic().font(.title2)
                }
            }
            else {
                NavigationStack {
                    BalanceSheetWindow(profile: profile).modelContainer(Containers.defaultContainer.0)
                }
            }
        }
        
        #if os(macOS)
        Settings {
            SettingsView().preferredColorScheme(colorScheme).modelContainer(globalContainer)
        }
        #else
        WindowGroup(id: "settings") {
            SettingsView().preferredColorScheme(colorScheme).modelContainer(globalContainer)
        }
        #endif
        
        WindowGroup(id: "help") {
            HelpView()
        }
    }
}

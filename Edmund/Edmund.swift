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
        
        #if os(macOS)
        Settings {
            SettingsView().preferredColorScheme(colorScheme)
        }
        #endif
        
        WindowGroup(id: "help") {
            HelpView()
        }
    }
}

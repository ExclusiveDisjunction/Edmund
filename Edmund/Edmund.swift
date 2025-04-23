//
//  ui_demoApp.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore
import WidgetKit

#if os(iOS)
import BackgroundTasks
#endif

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
        
#if os(iOS)
        EdmundApp.registerBackgroundTasks()
#elseif os(macOS)
        EdmundApp.refreshWidget()
#endif
    }
    
#if os(iOS)
    static func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.exdisj.edmund.refresh",
            using: nil) { task in
                handleAppRefresh(task: task)
            }
    }
    
    static func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.exdisj.edmund.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 24 * 60) //10 days from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled")
        } catch {
            print("The background task could not be made \(error)")
        }
    }
    static func handleAppRefresh(task: BGTask) {
        scheduleAppRefresh()
        
        task.expirationHandler = {
            print("App refresh canceled.")
        }
        
        Task {
            await saveUpcomingBills(context: Containers.personalContainer.mainContext)
            WidgetCenter.shared.reloadAllTimelines()
            print("Completed saving to upcoming bills");
            
            task.setTaskCompleted(success: true)
        }
    }
#else
    static func refreshWidget() {
        Task {
            await saveUpcomingBills(context: Containers.personalContainer.mainContext)
            print("Completed saving to upcoming bills");
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
#endif
    
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
                    Text("Unable to switch profile").italic().font(.title2)
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
                    Text("Unable to switch profile").italic().font(.title2)
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
        #endif
        
        WindowGroup(id: "help") {
            HelpView()
        }
    }
}

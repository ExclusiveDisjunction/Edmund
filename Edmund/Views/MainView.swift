//
//  ContentView.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

struct AddProfileView : View {
    @Binding var profiles: [Profile];
    @Binding var selectedProfile: Profile.ID;
    var globalContext: ModelContext;
    @State private var name: String = "";
    @Environment(\.dismiss) private var dismiss;
    @State private var duplicateAlert = false
    @State private var emptyAlert = false
    @State private var switchOnClose = true
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Profile Name")) {
                    TextField("Name", text: $name).labelsHidden()
                }
                
                Section {
                    Toggle("View on Creation", isOn: $switchOnClose)
                }
            }
            
            
            HStack {
                Spacer()
                Button("Cancel", action: {
                    dismiss()
                }).buttonStyle(.bordered)
                Button("Ok", action: {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        emptyAlert = true
                        return
                    }
                    for profile in profiles {
                        if profile.name == name {
                            duplicateAlert = true
                            return
                        }
                    }
                    
                    let profile = Profile(trimmed)
                    profiles.append(profile)
                    globalContext.insert(profile)
                    if switchOnClose {
                        selectedProfile = profile.id
                    }
                    dismiss()
                }).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}
@Observable
class ActiveProfile : Identifiable {
    init(name: String, container: ModelContainer) {
        self.name = name
        self.container = container
    }
    
    var id: String { self.name }
    var name: String;
    var container: ModelContainer;
}

struct MainView: View {
    @AppStorage("enableTransactions") var enableTransactions: Bool?;
    @State private var balance_vm: BalanceSheetVM = .init();
    @State private var accCatvm: AccountsCategoriesVM = .init();
    
    init(current: (ModelContainer, ContainerNames), global: ModelContainer, profiles: Binding<[Profile]>) {
        self.activeProfile = .init(name: current.1.name, container: current.0)
        self.globalContainer = global
        self._profiles = profiles
    }
    
    @Bindable private var activeProfile: ActiveProfile;
    private var globalContainer: ModelContainer;
    @Binding private var profiles: [Profile];
    
    @State private var showProfileFailure: Bool = false;
    @State private var showProfileSettings = false;
    
    @State private var showingSettings = false;
    @State private var showingHelp = false;
    
    @Environment(\.openWindow) private var openWindow;
#if os(macOS)
    @Environment(\.openSettings) private var openSettings;
#endif
    
    private var canPopoutWindow: Bool {
#if os(macOS)
        return true
#else
        if #available(iOS 16.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        return false
#endif
    }
    
    @ViewBuilder
    private var navLinks: some View {
        List {
            NavigationLink {
                Homepage()
            } label: {
                Text("Home")
            }
            
            if enableTransactions ?? true {
                NavigationLink {
                    LedgerTable(profile: $activeProfile.name)
                } label: {
                    Text("Ledger")
                }
                
                NavigationLink {
                    BalanceSheet(profile: $activeProfile.name, vm: balance_vm)
                } label: {
                    Text("Balance Sheet")
                }
            }
            
            NavigationLink {
                AllBillsViewEdit()
            } label: {
                Text("Bills")
            }
            
            NavigationLink {
                
            } label: {
                Text("Budget")
            }
            
            NavigationLink {
                AccountsCategories(vm: accCatvm)
            } label: {
                Text("Organization")
            }
        }
    }
    
    private func showSettings() {
        #if os(macOS)
        openSettings()
        #else
        showingSettings = true
        #endif
    }
    private func showHelp() {
        if canPopoutWindow {
            openWindow(id: "help")
        }
        else {
            showingHelp = true
        }
    }
    
    private func profileChanged(oldProfile: String, newProfile: String) {
        do {
            let containerID: ContainerNames;
            
            if newProfile == ContainerNames.debug.name {
                containerID = .debug
            }
            else if newProfile == ContainerNames.personal.name {
                containerID = .personal
            }
            else {
                containerID = .named(newProfile)
            }
            
            do {
                try activeProfile.container.mainContext.save()
            }
            catch {
                fatalError("Unable to save model to disk \(error)")
            }
            activeProfile.container = try Containers.getContainer(containerID)
        }
        catch {
            showProfileFailure = true
            profiles.removeAll(where: {$0.name == newProfile })
            
            print(error.localizedDescription)
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund").font(.title).padding(.bottom).backgroundStyle(.background.secondary)
                
                navLinks
                
                Spacer()
                
                HStack {
                    Button(action: showSettings) {
                        Image(systemName: "gear")
                    }.buttonStyle(.borderedProminent)
                    Button(action: showHelp) {
                        Image(systemName: "questionmark.circle")
                    }.buttonStyle(.borderedProminent)
                }
                Picker("Profile", selection: $activeProfile.name) {
                    ForEach(profiles, id: \.id) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }.labelsHidden().padding()
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }.onChange(of: activeProfile.name, profileChanged).alert("Unable to switch profile", isPresented: $showProfileFailure, actions: {
            Button("Ok", action: {
                showProfileFailure = false
            })
        }, message: {
            Text("The profile you selected could not be opened.")
        }).sheet(isPresented: $showingHelp) {
            HelpView()
        }.sheet(isPresented: $showingSettings) {
            SettingsView().modelContainer(globalContainer)
        }.modelContainer(activeProfile.container)
    }
}

#Preview {
    var profiles = Profile.debugProfiles;
    let profileBind = Binding(
        get: { profiles },
        set: { profiles = $0 }
    )
    
    MainView(current: (Containers.debugContainer, .debug), global: Containers.globalContainer, profiles: profileBind).frame(width: 800, height: 600)
}

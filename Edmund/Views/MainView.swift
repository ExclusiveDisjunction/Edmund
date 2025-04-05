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

struct MainView: View {
    @AppStorage("enableTransactions") var enableTransactions: Bool?;
    @State private var balance_vm: BalanceSheetVM = .init();
    @State private var accCatvm: AccountsCategoriesVM = .init();
    
    init(current: (ModelContainer, ContainerNames), global: ModelContainer, profiles: Binding<[Profile]>) {
        self.currentContainer = current.0
        self.globalContainer = global
        self._profiles = profiles
        self.selectedProfile = current.1.name
    }
    
    @State private var currentContainer: ModelContainer;
    private var globalContainer: ModelContainer;
    @Binding private var profiles: [Profile];
    @State private var selectedProfile: Profile.ID;
    
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
                    LedgerTable(profile: $selectedProfile)
                } label: {
                    Text("Ledger")
                }
                
                NavigationLink {
                    BalanceSheet(profile: $selectedProfile, vm: balance_vm)
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
        if canPopoutWindow {
#if os(macOS)
            openSettings()
#else
            openWindow(id: "settings")
#endif
        }
        else {
            showingSettings = true
        }
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
                try currentContainer.mainContext.save()
            }
            catch {
                fatalError("Unable to save model to disk \(error)")
            }
            currentContainer = try Containers.getContainer(containerID)
            
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
                VStack {
                    Text("Edmund").font(.title)
                    Text("Personal Finances").font(.subheadline).italic()
                    Text("Viewing profile '\(selectedProfile)'").font(.subheadline)
                }.padding(.bottom).backgroundStyle(.background.secondary)
                
                navLinks
                
                Spacer()
                
                HStack {
                    Button(action: showSettings) {
                        Label("Settings", systemImage: "gear")
                    }
                    Button(action: showHelp) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }
                Picker("Profile", selection: $selectedProfile) {
                    ForEach(profiles, id: \.id) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }.labelsHidden().padding()
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }.modelContainer(currentContainer).onChange(of: selectedProfile, profileChanged).alert("Unable to switch profile", isPresented: $showProfileFailure, actions: {
            Button("Ok", action: {
                showProfileFailure = false
            })
        }, message: {
            Text("The profile you selected could not be opened.")
        }).sheet(isPresented: $showingHelp) {
            HelpView()
        }.sheet(isPresented: $showingSettings) {
            SettingsView().modelContainer(globalContainer)
        }
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

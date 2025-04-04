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
    @State private var showingAddProfile = false;

    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Edmund").font(.title)
                Text("Personal Finances").font(.subheadline).italic()
                Text("Viewing profile '\(selectedProfile)'").font(.subheadline)
                List {
                    NavigationLink {
                        Homepage()
                    } label: {
                        Text("Home")
                    }
                    
                    if enableTransactions ?? true {
                        NavigationLink {
                            LedgerTable()
                        } label: {
                            Text("Ledger")
                        }
                        
                        NavigationLink {
                            BalanceSheet(vm: balance_vm)
                        } label: {
                            Text("Balance Sheet")
                        }
                        
                        NavigationLink {
                            AllNamedPairViewEdit<Account>()
                        } label: {
                            Text("Accounts")
                        }
                        
                        NavigationLink {
                            AllNamedPairViewEdit<Category>()
                        } label: {
                            Text("Categories")
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
                    
#if os(iOS)
                    NavigationLink {
                        SettingsView().navigationTitle("Settings")
                    } label: {
                        Text("Settings")
                    }
#endif
                }
                
                Spacer()
                
                HStack {
                    Picker("Profile", selection: $selectedProfile) {
                        ForEach(profiles, id: \.id) { profile in
                            Text(profile.name).tag(profile.id)
                        }
                    }.labelsHidden()
                    
                    Button(action: {
                        showingAddProfile = true
                    }) {
                        Image(systemName: "plus")
                    }
                }.padding()
            }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }.modelContainer(currentContainer).onChange(of: selectedProfile) { oldProfile, newProfile in
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
        }.alert("Unable to switch profile", isPresented: $showProfileFailure, actions: {
            Button("Ok", action: {
                showProfileFailure = false
            })
        }, message: {
            Text("The profile you selected could not be opened.")
        }).sheet(isPresented: $showingAddProfile) {
            AddProfileView(profiles: $profiles, selectedProfile: $selectedProfile, globalContext: globalContainer.mainContext)
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

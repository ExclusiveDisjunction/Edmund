//
//  AccountsIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct AccountsIE : View {
    @Query private var accounts: [Account];
    @State private var selection = Set<Account.ID>();
    
    @Bindable private var inspecting = InspectionManifest<Account>();
    @Bindable private var delete = DeletingManifest<Account>();
    @Bindable private var warning = WarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var compact: some View {
        List(accounts, selection: $selection) { account in
            
        }
    }
    
    @ViewBuilder
    private var expanded: some View {
        Table(accounts, selection: $selection) {
            TableColumn("Name", value: \.name)
            
            
        }
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                expanded
            }
        }.padding()
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Account") {
                            inspecting.open(.init(account: .init()), mode: .add)
                        }
                        Button("Sub Account") {
                            inspecting.open(.init(subAccount: .init()), mode: .add)
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                
                GeneralIEToolbarButton(on: cache, selection: $selection, inspect: inspecting, warning: warning, role: .edit, placement: .primaryAction)
                
                GeneralDeleteToolbarButton(on: cache, selection: $selection, delete: delete, warning: warning, placement: .primaryAction)
            }.task { refresh() }
            .toolbarRole(.editor)
            .sheet(item: $inspecting.value) { item in
                if let account = item.target as? Account {
                    ElementEditor(account, adding: inspecting.mode == .add)
                }
                else if let subAccount = item.target as? SubAccount {
                    ElementEditor(subAccount, adding: inspecting.mode == .add)
                }
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting) {
                AbstractDeletingActionConfirm(delete, delete: deleteFromModel, post: refresh)
            }
    }
}

#Preview {
    AccountsIE()
        .modelContainer(Containers.debugContainer)
}

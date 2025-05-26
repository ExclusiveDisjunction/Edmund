//
//  AccountsIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct AccountTableRow : Identifiable {
    init(subAccount: SubAccount) {
        self.id = UUID();
        self.target = subAccount;
        self.name = subAccount.name;
        self.creditLimit = nil;
        self.children = nil;
    }
    init(account: Account) {
        self.id = UUID();
        self.target = account;
        self.name = account.name;
        self.creditLimit = account.creditLimit;
        self.children = account.children?.map { Self(subAccount: $0) }
    }
    
    let target: any InspectableElement
    let id: UUID;
    let name: String;
    let creditLimit: Decimal?;
    let children: [AccountTableRow]?;
}

struct AccountsIE : View {
    @Query private var accounts: [Account];
    @State private var selection = Set<AccountTableRow.ID>();
    @State private var cache: [AccountTableRow] = [];
    
    @Bindable private var inspecting = InspectionManifest<AccountTableRow>();
    @Bindable private var delete = DeletingManifest<AccountTableRow>();
    @Bindable private var warning = WarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        self.cache = self.accounts.map { AccountTableRow(account: $0) }
    }
    private func deleteFromModel(data: AccountTableRow, context: ModelContext) {
        withAnimation {
            if let account = data.target as? Account {
                context.delete(account)
            }
            else if let subAccount = data.target as? SubAccount {
                context.delete(subAccount)
            }
        }
    }
    
    var body: some View {
        VStack {
            List(cache, children: \.children, selection: $selection) { acc in
                HStack {
                    Text(acc.name)
                    Spacer()
                    if let credit = acc.creditLimit {
                        Text("Credit Limit: \(credit, format: .currency(code: currencyCode))")
                    }
                }
            }.contextMenu(forSelectionType: AccountTableRow.ID.self) {
                SelectionContextMenu($0, data: cache, inspect: inspecting, delete: delete, warning: warning, canView: false)
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
                
                GeneralDeleteToolbarButton(on: cache, selection: $selection, delete: delete, warning: warning)
                
                ToolbarItem(placement: .primaryAction) {
                    
                }
            }.task { refresh() }
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

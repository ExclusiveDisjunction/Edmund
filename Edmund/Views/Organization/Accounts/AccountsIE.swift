//
//  AccountsIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData
import EdmundCore

fileprivate struct AccountWrapper : Identifiable {
    init(_ data: Account, id: UUID = UUID()) {
        self.id = id
        self.data = data
    }
    
    var id: UUID;
    var data: Account
}

struct AccountsIE : View {
    @Query(sort: [SortDescriptor(\Account.name, order: .forward)] ) private var accounts: [Account];
    @State private var wrappers: [AccountWrapper] = [];
    @State private var selection = Set<AccountWrapper.ID>();
    @State private var showingSubAccounts: AccountWrapper? = nil;
    
    @Bindable private var inspecting = InspectionManifest<AccountWrapper>();
    @Bindable private var delete = DeletingManifest<AccountWrapper>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        wrappers = accounts.map { .init($0) }
    }
    
    @ViewBuilder
    private var expanded: some View {
        Table(wrappers, selection: $selection) {
            TableColumn("Name") { account in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(account.data.name)
                        Spacer()
                        Text("Kind:")
                        Text(account.data.kind.display)
                    }.swipeActions(edge: .trailing) {
                        SingularContextMenu(account, inspect: inspecting, remove: delete, asSlide: true)
                    }
                }
                else {
                    Text(account.data.name)
                }
            }
            TableColumn("Kind") { account in
                Text(account.data.kind.display)
            }
            TableColumn("Credit Limit") { account in
                if let limit = account.data.creditLimit {
                    Text(limit, format: .currency(code: currencyCode))
                }
                else {
                    Text("No credit limit")
                        .italic()
                }
            }
            TableColumn("Interest") { account in
                if let interest = account.data.interest {
                    Text(interest, format: .percent.precision(.fractionLength(3)))
                }
                else {
                    Text("No interest")
                        .italic()
                }
            }
            TableColumn("Location") { account in
                if let location = account.data.location {
                    Text(location)
                }
                else {
                    Text("No location")
                        .italic()
                }
            }
        }.contextMenu(forSelectionType: AccountWrapper.ID.self) { selection in
            SelectionContextMenu(selection, data: wrappers, inspect: inspecting, delete: delete, warning: warning)
            
            Divider()
            
            Button {
                if let id = selection.first, let element = wrappers.first(where: { $0.id == id } ) {
                    showingSubAccounts = element
                }
            } label: {
                Label("Sub Accounts", systemImage: "list.bullet.rectangle")
            }.disabled(selection.count != 1)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                inspecting.open(.init(.init()), mode: .add)
            }) {
                Label("Add", systemImage: "plus")
            }
        }
        
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: wrappers, selection: $selection, inspect: inspecting, warning: warning, role: .edit, placement: .primaryAction)
            GeneralIEToolbarButton(on: wrappers, selection: $selection, inspect: inspecting, warning: warning, role: .inspect, placement: .primaryAction)
        }
        
        GeneralDeleteToolbarButton(on: wrappers, selection: $selection, delete: delete, warning: warning, placement: .primaryAction)
        
#if os(iOS)
        ToolbarItem(placement: .primaryAction) {
            EditButton()
        }
#endif
    }
    
    var body: some View {
        VStack {
            expanded
        }.padding()
            .navigationTitle("Accounts")
            .toolbar {
                toolbarContent
            }
            .toolbarRole(.editor)
            .sheet(item: $inspecting.value) { item in
                ElementIE(item.data, mode: inspecting.mode)
            }
            .sheet(item: $showingSubAccounts) { acc in
                SubAccountsIE(acc.data, isSheet: true)
                    .padding()
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting, titleVisibility: .visible) {
                AbstractDeletingActionConfirm(delete) { account, context in
                    context.delete(account.data)
                    Task {
                        await uniqueEngine.releaseId(key: Account.objId, id: account.data.id)
                    }
                }
            }.onAppear(perform: refresh)
            .onChange(of: accounts) { _, _ in
                refresh()
            }
    }
}

#Preview {
    DebugContainerView {
        AccountsIE()
    }
}

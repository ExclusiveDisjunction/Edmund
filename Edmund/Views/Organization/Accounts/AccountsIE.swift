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
    @Query(sort: [SortDescriptor(\Account.name, order: .forward)] ) private var accounts: [Account];
    @State private var selection = Set<Account.ID>();
    
    @Bindable private var inspecting = InspectionManifest<Account>();
    @Bindable private var delete = DeletingManifest<Account>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var expanded: some View {
        Table(accounts, selection: $selection) {
            TableColumn("Name") { account in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(account.name)
                        Spacer()
                        Text("Kind:")
                        Text(account.kind.display)
                    }.swipeActions(edge: .trailing) {
                        SingularContextMenu(account, inspect: inspecting, remove: delete, asSlide: true)
                    }
                }
                else {
                    Text(account.name)
                }
            }
            TableColumn("Kind") { account in
                Text(account.kind.display)
            }
            TableColumn("Credit Limit") { account in
                if let limit = account.creditLimit {
                    Text(limit, format: .currency(code: currencyCode))
                }
                else {
                    Text("No credit limit")
                        .italic()
                }
            }
            TableColumn("Interest") { account in
                if let interest = account.interest {
                    Text(interest, format: .percent.precision(.fractionLength(3)))
                }
                else {
                    Text("No interest")
                        .italic()
                }
            }
            TableColumn("Location") { account in
                if let location = account.location {
                    Text(location)
                }
                else {
                    Text("No location")
                        .italic()
                }
            }
        }.contextMenu(forSelectionType: Account.ID.self) { selection in
            SelectionContextMenu(selection, data: accounts, inspect: inspecting, delete: delete, warning: warning)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                inspecting.open(Account(), mode: .add)
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: accounts, selection: $selection, inspect: inspecting, warning: warning, role: .edit, placement: .primaryAction)
            GeneralIEToolbarButton(on: accounts, selection: $selection, inspect: inspecting, warning: warning, role: .inspect, placement: .primaryAction)
        }
        
        GeneralDeleteToolbarButton(on: accounts, selection: $selection, delete: delete, warning: warning, placement: .primaryAction)
        
#if os(iOS)
        ToolbarItem(placement: .primaryAction) {
            EditButton()
        }
#endif
    }
    
    var body: some View {
        expanded
            .padding()
            .navigationTitle("Accounts")
            .toolbar {
                toolbarContent
            }
            .toolbarRole(.editor)
            .sheet(item: $inspecting.value) { item in
                ElementIE(item, mode: inspecting.mode)
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok") {
                    warning.isPresented = false
                }
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting, titleVisibility: .visible) {
                UniqueDeletingActionConfirm(delete)
            }
    }
}

#Preview {
    DebugContainerView {
        AccountsIE()
    }
}

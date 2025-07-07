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
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var compact: some View {
        List(accounts, selection: $selection) { account in
            HStack {
                Text(account.name)
                Spacer()
                Text("Kind:")
                Text(account.kind.display)
            }.swipeActions(edge: .trailing) {
                SingularContextMenu(account, inspect: inspecting, remove: delete, asSlide: true)
            }
        }.contextMenu(forSelectionType: Account.ID.self) { selection in
            SelectionContextMenu(selection, data: accounts, inspect: inspecting, delete: delete, warning: warning)
        }
    }
    
    @ViewBuilder
    private var expanded: some View {
        Table(accounts, selection: $selection) {
            TableColumn("Name", value: \.name)
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
                    Button(action: {
                        inspecting.open(.init(), mode: .add)
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                }
                
                GeneralIEToolbarButton(on: accounts, selection: $selection, inspect: inspecting, warning: warning, role: .edit, placement: .primaryAction)
                GeneralIEToolbarButton(on: accounts, selection: $selection, inspect: inspecting, warning: warning, role: .inspect, placement: .primaryAction)
                
                GeneralDeleteToolbarButton(on: accounts, selection: $selection, delete: delete, warning: warning, placement: .primaryAction)
            }
            .toolbarRole(.editor)
            .sheet(item: $inspecting.value) { item in
                ElementIE(item, mode: inspecting.mode)
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting) {
                DeletingActionConfirm(delete)
            }
    }
}

#Preview {
    DebugContainerView {
        AccountsIE()
    }
}

//
//  AccountsIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData
import EdmundCore

fileprivate enum AnyAccount {
    case account(Account)
    case subAccount(SubAccount)
    case addButton(Account)
}

fileprivate struct AccountWrapper : Identifiable {
    init(_ data: Account, id: UUID = UUID()) {
        self.id = id
        self.data = .account(data)
        self.children = data.children.map { AccountWrapper($0) } + [ AccountWrapper(addButton: data) ]
    }
    init(_ data: SubAccount, id: UUID = UUID()) {
        self.id = id
        self.data = .subAccount(data)
    }
    init(addButton: Account, id: UUID = UUID()) {
        self.data = .addButton(addButton)
        self.id = id
    }
    
    var id: UUID;
    var data: AnyAccount
    var children: [AccountWrapper]?;
    
    var name: String {
        get {
            switch self.data {
                case .account(let a): a.name
                case .subAccount(let a): a.name
                case .addButton(_): "Edit Sub Accounts"
            }
        }
        set {
            switch self.data {
                case .account(let a): a.name = newValue
                case .subAccount(let a): a.name = newValue
                case .addButton(_): return
            }
        }
    }
}

struct AccountsIE : View {
    @Query(sort: [SortDescriptor(\Account.name, order: .forward)] ) private var accounts: [Account];
    @State private var wrappers: [AccountWrapper] = [];
    @State private var selection = Set<AccountWrapper.ID>();
    @State private var showingSubAccounts: Account? = nil;
    @State private var addingSubTo: Account? = nil;
    
    @Bindable private var inspecting = InspectionManifest<AccountWrapper>();
    @Bindable private var delete = DeletingManifest<AccountWrapper>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        wrappers = accounts.map { .init($0) }
    }
    private func getCurrentlySelected(_ outOf: Set<AccountWrapper.ID>?, onlyOne: Bool) -> AnyAccount? {
        let outOf = (outOf != nil ? outOf! : selection);
        
        guard let id = outOf.first, let first = wrappers.first(where: { $0.id == id } ) else {
            return nil
        }
        
        if onlyOne && outOf.count != 1 {
            return nil
        }
        
        return first.data
    }
    private func addSubAccount() {
        guard let selection = getCurrentlySelected(nil, onlyOne: true) else {
            warning.warning = selection.isEmpty ? .noneSelected : .tooMany
            return
        }
        
        addingSubTo = switch selection {
            case .account(let a): a
            case .subAccount(let s): s.parent
            case .addButton(let a): a
        };
    }
    
    @ViewBuilder
    private func nameColumn(_ row: AccountWrapper) -> some View {
        if case .addButton(let source) = row.data {
            Button {
                showingSubAccounts = source
            } label: {
                Label("Edit Sub Accounts", systemImage: "pencil")
            }
        }
        else {
            if horizontalSizeClass == .compact {
                HStack {
                    Text(row.name)
                    Spacer()
                    if case .account(let a) = row.data {
                        Text("Type:")
                            .italic()
                        Text(a.kind.display)
                            .italic()
                    }
                }.swipeActions(edge: .trailing) {
                    SingularContextMenu(row, inspect: inspecting, remove: delete, asSlide: true)
                }
            }
            else {
                Text(row.name)
            }
        }
    }
    
    @ViewBuilder
    private var expanded: some View {
        Table(wrappers, children: \.children, selection: $selection) {
            TableColumn("Name", content: nameColumn)
            TableColumn("Kind") { row in
                if case .account(let account) = row.data {
                    Text(account.kind.display)
                }
            }
            TableColumn("Credit Limit") { row in
                if case .account(let account) = row.data {
                    if let limit = account.creditLimit {
                        Text(limit, format: .currency(code: currencyCode))
                    }
                    else {
                        Text("No credit limit")
                            .italic()
                    }
                }
            }
            TableColumn("Interest") { row in
                if case .account(let account) = row.data {
                    if let interest = account.interest {
                        Text(interest, format: .percent.precision(.fractionLength(3)))
                    }
                    else {
                        Text("No interest")
                            .italic()
                    }
                }
            }
            TableColumn("Location") { row in
                if case .account(let account) = row.data {
                    if let location = account.location {
                        Text(location)
                    }
                    else {
                        Text("No location")
                            .italic()
                    }
                }
            }
        }.contextMenu(forSelectionType: AccountWrapper.ID.self) { selection in
            SelectionContextMenu(selection, data: wrappers, inspect: inspecting, delete: delete, warning: warning)
            
            Divider()
            
            Button {
                if let id = selection.first,
                   let element = wrappers.first(where: { $0.id == id } ),
                   case .account(let account) = element.data {
                    showingSubAccounts = account
                }
            } label: {
                Label("Sub Accounts", systemImage: "list.bullet.rectangle")
            }.disabled(selection.count != 1)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    inspecting.open(.init(Account()), mode: .add)
                } label: {
                    Text("Account")
                }
                
                Button {
                    addSubAccount()
                } label: {
                    Text("Sub Account")
                }
            } label: {
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
        expanded
            .padding()
            .navigationTitle("Accounts")
            .onAppear(perform: refresh)
            .onChange(of: accounts) { _, _ in
                refresh()
            }
            .toolbar {
                toolbarContent
            }
            .sheet(item: $inspecting.value) { item in
                if case .account(let a) = item.data {
                    ElementIE(a, mode: inspecting.mode)
                }
                else {
                    VStack {
                        Spacer()
                        
                        Text("internalError")
                        
                        Spacer()
                    }
                }
            }
            .sheet(item: $showingSubAccounts) { acc in
                SubAccountsIE(acc, isSheet: true)
                    .padding()
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok") {
                    warning.isPresented = false
                }
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting, titleVisibility: .visible) {
                AbstractDeletingActionConfirm(delete) { account, context in
                    switch account.data {
                        case .account(let a):
                            context.delete(a)
                            Task {
                                await uniqueEngine.releaseId(key: Account.objId, id: a.id)
                            }
                        case .subAccount(let s):
                            context.delete(s)
                            Task {
                                await uniqueEngine.releaseId(key: SubAccount.objId, id: s.id)
                            }
                        case .addButton(_): return
                    }
                }
            }
    }
}

#Preview {
    DebugContainerView {
        AccountsIE()
    }
}

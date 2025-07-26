//
//  SubAccountsInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/24/25.
//

import SwiftUI
import SwiftData
import EdmundCore

/// A view used to inspect, edit, and remove the sub accounts from a specific account.
public struct SubAccountsIE : View {
    public init(_ source: Account, isSheet: Bool = false) {
        self.source = source
        self.isSheet = isSheet
    }
    private let source: Account;
    private let isSheet: Bool;
    
    @Observable
    class Row : Identifiable {
        init(_ data: SubAccount, id: UUID = UUID()) {
            self.data = data
            self.working = data.name
            self.id = id
            self.isEditing = false;
            self.attempts = 0;
        }
        
        let id: UUID;
        let data: SubAccount;
        var working: String;
        var isEditing: Bool = false;
        var attempts: CGFloat = 0;
    }
    
    @State private var cache: [Row] = [];
    @State private var selection: Set<Row.ID> = .init();
    @State private var adding: Bool = false;
    @State private var working: String = "";
    @State private var failedAttempts: CGFloat = .init();
    @Bindable private var delete = DeletingManifest<Row>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.loggerSystem) private var loggers;
    
    private func refresh() {
        cache = source.children.sorted(using: KeyPathComparator(\.name)).map { Row($0) }
    }
    @MainActor
    private func addNew() async {
        let name = working.trimmingCharacters(in: .whitespacesAndNewlines);
        if !name.isEmpty {
            let newId = BoundPairID(parent: source.name, name: name);
            
            if await uniqueEngine.reserveId(key: SubAccount.objId, id: newId) {
                let new = SubAccount(parent: source)
                new.name = name;
                
                modelContext.insert(new);
                adding = false;
                return;
            }
        }
        
        withAnimation {
            failedAttempts += 1;
        }
    }
    @MainActor
    private func submitFor(_ row: Row) async {
        let name = row.working.trimmingCharacters(in: .whitespacesAndNewlines);
        
        if !name.isEmpty {
            if await row.data.tryNewName(name: name, unique: uniqueEngine) {
                do {
                    try await row.data.takeNewName(name: name, unique: uniqueEngine)
                }
                catch let e {
                    loggers?.data.error("Could not reserve new name \(name) for sub account, unique engine threw error \(e)");
                }
                
                row.isEditing = false;
                return;
            }
        }
        
        withAnimation {
            row.attempts += 1;
        }
    }
    
    @ViewBuilder
    private var header: some View {
        
    }
    
    public var body: some View {
        VStack {
            if isSheet {
                HStack {
                    Text("Sub Accounts")
                        .font(.title2)
                    
                    Spacer()
                }
            }
            
            HStack {
                Spacer()
                
                Button(action: { adding = true }) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                    .popover(isPresented: $adding) {
                        HStack {
                            Text("Name:")
                                .frame(width: 50)
                            TextField("", text: $working)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    Task {
                                        await addNew()
                                    }
                                }
                                .onDisappear {
                                    working = "";
                                }
                                .modifier(ShakeEffect(animatableData: CGFloat(failedAttempts)))
                                .frame(minWidth: 170)
                        }.padding()
                    }
                
                Button(action: {
                    delete.deleteSelected(selection, on: cache, warning: warning)
                } ) {
                    Image(systemName: "trash")
                }.foregroundStyle(.red)
                    .buttonStyle(.borderless)
                
#if os(iOS)
                EditButton()
#endif
            }
            
            List($cache, selection: $selection) { $row in
                HStack {
                    Text(row.data.name)
                        .popover(isPresented: $row.isEditing) {
                            HStack {
                                Text("Name:")
                                    .frame(width: 50)
                                TextField("", text: $row.working)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        Task {
                                            await submitFor(row)
                                        }
                                    }
                                    .onDisappear {
                                        row.working = row.data.name
                                    }
                                    .modifier(ShakeEffect(animatableData: CGFloat(row.attempts)))
                            }.padding()
                        }
                }.contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        row.isEditing = true
                    }
                    .contextMenu {
                        Button(action: {
                            row.isEditing = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            delete.action = [row]
                        }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
            }.frame(minHeight: 200)
                .contextMenu(forSelectionType: Row.ID.self) { selection in
                    Button(action: { adding = true }) {
                        Label("Add", systemImage: "plus")
                    }.buttonStyle(.borderless)
                    
                    Button(action: {
                        delete.deleteSelected(selection, on: cache, warning: warning)
                    } ) {
                        Label("Remove", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                        .disabled(selection.isEmpty)
                }
            
            if isSheet {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Ok", action: { dismiss() } )
                        .buttonStyle(.borderedProminent)
                }
            }
        }.onAppear(perform: refresh)
            .onChange(of: source.children) { _, _ in
                refresh()
            }
            .confirmationDialog("Do you want to delete these sub accounts, and all associated transactions?", isPresented: $delete.isDeleting) {
                AbstractDeletingActionConfirm(delete) { item, context in
                    context.delete(item.data)
                }
            }.alert("Error", isPresented: $warning.isPresented) {
                Button("Ok") {
                    warning.isPresented = false;
                }
            } message: {
                Text(warning.message ?? "internalError")
            }
    }
}

#Preview {
    SubAccountsIE(Account.exampleAccount)
}

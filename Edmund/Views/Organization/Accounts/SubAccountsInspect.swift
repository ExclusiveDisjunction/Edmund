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
public struct SubAccountsInspect : View {
    public let source: Account;
    
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
    @Bindable private var delete = DeletingManifest<Row>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.loggerSystem) private var loggers;
    
    private func refresh() {
        cache = source.children.map { Row($0) }
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
    
    public var body: some View {
        VStack {
            HStack {
                Text("Sub Accounts")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { adding = true }) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                
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
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.onAppear(perform: refresh)
            .onChange(of: source.children) { _, _ in
                refresh()
            }
            .padding()
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
    SubAccountsInspect(source: Account.exampleAccount)
}

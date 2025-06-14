//
//  ManualTransactions.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import SwiftData;
import Foundation;
import EdmundCore;

struct BatchTransactions: TransactionEditorProtocol {
    @State private var snapshots: [LedgerEntrySnapshot] = [.init()];
    @State private var selection: Set<LedgerEntrySnapshot.ID> = .init();
    @State private var enableDates: Bool = true;
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        var result: [LedgerEntry] = [];
        for snapshot in snapshots {
            if !snapshot.validate() {
                warning.warning = .init(message: "emptyFields")
                return false;
            }
            
            let entry = LedgerEntry();
            snapshot.apply(entry, context: modelContext)
            
            result.append(entry)
        }

        for item in result {
            modelContext.insert(item)
        }
        return true;
    }
    private func add_trans() {
        withAnimation {
            snapshots.append(.init())
        }
    }
    
    var body: some View {
        TransactionEditorFrame(.grouped, warning: warning, apply: apply, content: {
            VStack {
                Button(action: add_trans) {
                    Label("Add", systemImage: "plus")
                }
                
                Toggle("Enable Dates", isOn: $enableDates)
                
                Table($snapshots, selection: $selection) {
                    TableColumn("Memo") { $item in
                        TextField("", text: $item.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    TableColumn("Credit") { $item in
                        TextField("", value: $item.credit, format: .currency(code: currencyCode))
                            .textFieldStyle(.roundedBorder)
                    }
                    TableColumn("Debit") { $item in
                        TextField("", value: $item.debit, format: .currency(code: currencyCode))
                            .textFieldStyle(.roundedBorder)
                    }
                    TableColumn("Date") { $item in
                        DatePicker("", selection: $item.date, displayedComponents: .date)
                            .labelsHidden()
                            .disabled(!enableDates)
                    }
                    TableColumn("Location") { $item in
                        TextField("", text: $item.location)
                            .textFieldStyle(.roundedBorder)
                    }
                    TableColumn("Category") { $item in
                        NamedPairPicker($item.category)
                    }.width(170)
                    TableColumn("Account") { $item in
                        NamedPairPicker($item.account)
                    }.width(170)
                }
                .contextMenu(forSelectionType: LedgerEntrySnapshot.ID.self) { selection in
                    Button(action: add_trans) {
                        Label("Add", systemImage: "plus")
                    }
                    
                    if !selection.isEmpty {
                        Button(action: {
                            withAnimation {
                                self.snapshots.removeAll(where: { selection.contains($0.id)} )
                            }
                        }) {
                            Label("Remove", systemImage: "trans")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(minWidth: 500, minHeight: 300)
            }
        })
    }
}

#Preview {
    BatchTransactions()
        .modelContainer(Containers.debugContainer)
        .padding()
}

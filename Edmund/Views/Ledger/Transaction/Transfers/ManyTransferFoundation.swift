//
//  ManyTransferFoundation.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;
import EdmundCore

@Observable
class ManyTableEntry : Identifiable {
    init(amount: Decimal = 0, account: SubAccount? = nil, id: UUID = UUID()) {
        self.amount = .init(rawValue: amount);
        self.account = account;
        self.id = id;
        self.selected = false;
    }
    
    
    var id: UUID;
    var selected: Bool;
    var amount: CurrencyValue;
    var account: SubAccount?;
}

extension [ManyTableEntry] {
    /// Takes in the current information and builds `LedgerEntry` instances from it. If `transfer_into` is true, these will be in the form of "Various to [account]"
    func createTransactions(transfer_into: Bool, _ cats: CategoriesContext) throws(ValidationException) -> [LedgerEntry] {
        var result: [LedgerEntry] = [];
        var failures: [ValidationFailure] = [];
        for (id, entry) in self.enumerated() {
            guard let acc = entry.account else {
                failures.append(.empty("Line \(id + 1): Account"))
                continue;
            }
            
            result.append(
                .init(
                    name: (transfer_into ? "Various to " + acc.name : acc.name + " to Various"),
                    credit: transfer_into ? entry.amount.rawValue : 0,
                    debit: transfer_into ? 0 : entry.amount.rawValue,
                    date: Date.now,
                    location: "Bank",
                    category: cats.accountControl.transfer,
                    account: acc
                )
            );
        }
        
        guard failures.isEmpty else {
            throw ValidationException(failures)
        }
        
        return result;
    }
    
    var amount: Decimal {
        self.reduce(into: Decimal(), { $0 += $1.amount.rawValue } )
    }
}

struct ManyTransferTable : View {
    @Binding var data: [ManyTableEntry];
    @State private var editing: ManyTableEntry? = nil;
    @State private var selected = Set<ManyTableEntry.ID>();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func removeSelected() {
        data.removeAll(where: { $0.selected} )
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: {
            withAnimation {
                data.append(.init())
            }
        }) {
            Label("Add", systemImage: "plus")
        }.buttonStyle(.borderless)
    }
    
    @ViewBuilder
    private var compact: some View {
        List(data, selection: $selected) { item in
            HStack {
                Text(item.amount.rawValue, format: .currency(code: currencyCode))
                if let account = item.account {
                    CompactNamedPairInspect(account)
                }
                else {
                    Text("No Account").italic()
                }
            }.swipeActions(edge: .leading) {
                Button(action: {
                    editing = item
                }) {
                    Image(systemName: "pencil")
                }.tint(.green)
            }
        }.contextMenu(forSelectionType: ManyTableEntry.ID.self, menu: itemContextMenu)
    }
    
    @ViewBuilder
    private func itemContextMenu(_ selection: Set<ManyTableEntry.ID>) -> some View {
        addButton
        Button(action: {
            self.data.removeAll(where: { selection.contains($0.id) } )
        }) {
            Label("Remove", systemImage: "trash")
        }
    }
    
    var body: some View {
        VStack {
#if os(iOS)
            HStack {
                addButton
                
                Spacer()
                
                EditButton()
            }
#else
            addButton
#endif
            
            Table($data, selection: $selected) {
                TableColumn("Amount") { $item in
                    CurrencyField(item.amount)
                }
                
                TableColumn("Account") { $item in
                    NamedPairPicker($item.account)
                }
            }.contextMenu(forSelectionType: ManyTableEntry.ID.self, menu: itemContextMenu)
        }
    }
}

#Preview {
    var data: [ManyTableEntry] = [.init(), .init()];
    let binding = Binding(
        get: { data },
        set: { data = $0 }
    );
    
    ManyTransferTable(data: binding)
        .padding()
        .modelContainer(Containers.debugContainer)
}

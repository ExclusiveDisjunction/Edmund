//
//  ManyTransferFoundation.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

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

struct ManyTableEntryEditor : View {
    init(_ data: Binding<ManyTableEntry>) {
        self._data = data;
    }
    
    @Binding var data: ManyTableEntry;
    @Environment(\.dismiss) private var dismiss;
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text("Amount:")
                    
                    CurrencyField(data.amount)
                }
                
                GridRow {
                    Text("Account:")
                    
                    NamedPairPicker($data.account)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Ok", action: { dismiss() } )
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

struct ManyTransferTable : View {
    let title: LocalizedStringKey?;
    @Binding var data: [ManyTableEntry];
    @State private var editing: Binding<ManyTableEntry>? = nil;
    @State private var selected = Set<ManyTableEntry.ID>();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func removeSelected(selection: Set<ManyTableEntry.ID>? = nil) {
        let trueSelection: Set<ManyTableEntry.ID>;
        if let selection = selection {
            trueSelection = selection
        }
        else {
            trueSelection = self.selected
        }
        
        data.removeAll(where: { trueSelection.contains($0.id ) } )
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
        List($data, selection: $selected) { $item in
            HStack {
                CurrencyField(item.amount)
                
                Spacer()
                
                NamedPairPicker($item.account)
                /*
                Text(item.amount.rawValue, format: .currency(code: currencyCode))
                
                Spacer()
                
                if let account = item.account {
                    CompactNamedPairInspect(account)
                }
                else {
                    Text("No Account").italic()
                }
                */
            }
        }.contextMenu(forSelectionType: ManyTableEntry.ID.self, menu: itemContextMenu)
    }
    
    @ViewBuilder
    private var fullSize: some View {
        Table($data, selection: $selected) {
            TableColumn("Amount") { $item in
                CurrencyField(item.amount)
            }
            
            TableColumn("Account") { $item in
                NamedPairPicker($item.account)
            }
        }.contextMenu(forSelectionType: ManyTableEntry.ID.self, menu: itemContextMenu)
    }
    
    @ViewBuilder
    private func itemContextMenu(_ selection: Set<ManyTableEntry.ID>) -> some View {
        addButton
        
        Button(action: {
            withAnimation {
                removeSelected(selection: selection)
            }
        }) {
            Label("Remove", systemImage: "trash")
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                if let title = self.title {
                    Text(title)
                        .bold()
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        data.append(.init())
                    }
                }) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                
                Button(action: {
                    withAnimation {
                        removeSelected()
                    }
                }) {
                    Image(systemName: "trash")
                }.foregroundStyle(.red)
                    .buttonStyle(.borderless)
                    .disabled(selected.isEmpty)
                
                #if os(iOS)
                EditButton()
                #endif
            }
            
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                fullSize
            }
        }
    }
}

#Preview {
    var data: [ManyTableEntry] = [.init(), .init()];
    let binding = Binding(
        get: { data },
        set: { data = $0 }
    );
    
    ManyTransferTable(title: nil, data: binding)
        .padding()
        .modelContainer(Containers.debugContainer)
}

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
    init(amount: Decimal = 0, account: Account? = nil, id: UUID = UUID()) {
        self.amount = .init(rawValue: amount);
        self.account = account;
        self.id = id;
        self.selected = false;
    }
    
    
    var id: UUID;
    var selected: Bool;
    var amount: CurrencyValue;
    var account: Account?;
}

@Observable
class ManyTableManifest {
    /// Creates a new manifest.
    /// - Parameters:
    ///     - isSource; When true, the transactions, when created, will be written like this instance is the source of the transfer. Specifically, this means the header will be "\(name) to Various"
    init(isSource: Bool, entries: [ManyTableEntry] = []) {
        self.isSource = isSource;
        self.entries = entries;
    }
    
    private let isSource: Bool;
    var entries: [ManyTableEntry];
    var selection: Set<ManyTableEntry.ID> = .init();
    
    var amount: Decimal {
        entries.reduce(into: Decimal(), { $0 += $1.amount.rawValue } )
    }
    
    func add() {
        withAnimation {
            entries.append(.init())
        }
    }
    func removeSelected(_ selection: Set<ManyTableEntry.ID>? = nil) {
        let trueSelection = selection != nil ? selection! : self.selection;
        
        withAnimation {
            self.entries.removeAll(where: { trueSelection.contains($0.id) } )
        }
    }
    
    func createTransactions(date: Date, cats: CategoriesContext) throws(ValidationFailure) -> [LedgerEntry] {
        var result: [LedgerEntry] = .init()
        result.reserveCapacity(self.entries.count)
        
        let bank = NSLocalizedString("Bank", comment: "")
        
        for row in self.entries {
            guard let acc = row.account else {
                throw .empty
            }
            let amount = row.amount.rawValue;
            
            result.append(
                LedgerEntry(
                    name: isSource ? "\(acc.name) to Various" : "Various to \(acc.name)",
                    credit: isSource ? 0 : amount,
                    debit: isSource ? amount : 0,
                    date: date,
                    location: bank,
                    category: cats.transfers,
                    account: acc)
            )
        }
        
        return result;
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
                    
                    ElementPicker($data.account)
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
    @Bindable var data: ManyTableManifest;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var addButton: some View {
        Button {
            data.add()
        } label: {
            Label("Add", systemImage: "plus")
        }.buttonStyle(.borderless)
    }
    
    @ViewBuilder
    private var fullSize: some View {
        Table($data.entries, selection: $data.selection) {
            TableColumn("Amount") { $item in
                if horizontalSizeClass == .compact {
                    HStack {
                        CurrencyField(item.amount)
                        
                        Spacer()
                        
                        ElementPicker($item.account)
                    }.swipeActions(edge: .trailing) {
                        Button {
                            withAnimation {
                                data.entries.removeAll(where: { $0.id == item.id } )
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }.tint(.red)
                    }
                }
                else {
                    CurrencyField(item.amount)
                }
            }
            
            TableColumn("Account") { $item in
                ElementPicker($item.account)
            }
        }.contextMenu(forSelectionType: ManyTableEntry.ID.self) { selection in
            addButton
            
            Button {
                data.removeSelected(selection)
            } label: {
                Label("Remove", systemImage: "trash")
            }
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
                
                addButton
                
                Button {
                    data.removeSelected()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }.buttonStyle(.borderless)
                    .disabled(data.selection.isEmpty)
                
                #if os(iOS)
                EditButton()
                #endif
            }
            
            fullSize
        }
    }
}

#Preview {
    let manifest = ManyTableManifest(isSource: true, entries: [
        .init(),
        .init()
    ])
    
    DebugContainerView {
        ManyTransferTable(title: nil, data: manifest)
            .padding()
    }
}

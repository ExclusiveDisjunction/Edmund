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
        self.amount = amount;
        self.account = account;
        self.id = id;
        self.selected = false;
    }
    
    
    var id: UUID;
    var selected: Bool;
    var amount: Decimal;
    var account: SubAccount?;
}

extension [ManyTableEntry] {
    /// Takes in the current information and builds `LedgerEntry` instances from it. If `transfer_into` is true, these will be in the form of "Various to [account]"
    func createTransactions(transfer_into: Bool, _ cats: CategoriesContext) -> [LedgerEntry]? {
        var result: [LedgerEntry] = [];
        for entry in self {
            guard let acc = entry.account else { return nil; }
            
            result.append(
                .init(
                    name: (transfer_into ? "Various to " + acc.name : acc.name + " to Various"),
                    credit: transfer_into ? entry.amount : 0,
                    debit: transfer_into ? 0 : entry.amount,
                    date: Date.now,
                    location: "Bank",
                    category: cats.accountControl.transfer,
                    account: acc
                )
            );
        }
        
        return result;
    }
    
    var amount: Decimal {
        self.reduce(into: Decimal(), { $0 += $1.amount } )
    }
}

struct ManyTransferTable : View {
    @Binding var data: [ManyTableEntry];
    @State private var selected = Set<ManyTableEntry.ID>();
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func removeSelected() {
        data.removeAll(where: { $0.selected} )
    }
    
    var body: some View {
        HStack {
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
                Image(systemName: "trash").foregroundStyle(.red)
            }.buttonStyle(.borderless)
            
        }.padding(.top)
        
        ScrollView {
            Grid {
                GridRow {
                    Text("")
                    Text("Amount")
                    Text("Account")
                }
                Divider()
                
                ForEach($data) { $item in
                    GridRow {
                        Toggle("Selected", isOn: $item.selected).labelsHidden()
                        TextField("Amount", value: $item.amount, format: .currency(code: "USD")).disabled(item.selected)
                        NamedPairPicker($item.account).disabled(item.selected)
                    }.background(item.selected ? Color.accentColor.opacity(0.2) : Color.clear)
                }
            }.padding().background(.background.opacity(0.7))
        }
    }
}

#Preview {
    var data: [ManyTableEntry] = [];
    let binding = Binding(
        get: { data },
        set: { data = $0 }
    );
    
    ManyTransferTable(data: binding).modelContainer(Containers.debugContainer)
}

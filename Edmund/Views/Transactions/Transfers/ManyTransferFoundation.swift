//
//  ManyTransferFoundation.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

@Observable
class ManyTableEntry : Identifiable {
    init() {
        self.amount = 0;
        self.account = nil;
        self.id = UUID();
        self.selected = false;
    }
    
    
    var id: UUID;
    var selected: Bool;
    var amount: Decimal;
    var account: SubAccount?;
}

@Observable
class ManyTransferTableVM {
    init() {
        entries = [ManyTableEntry()];
    }
    
    func clear() {
        entries.forEach { $0.selected = true } //Ensures that no editing happens
        entries = [ManyTableEntry()];
    }
    
    func get_empty_rows() -> [Int] {
        var result: [Int] = [];
        
        for (i, d) in entries.enumerated() {
            if d.account == nil {
                result.append(i)
            }
        }
        
        return result;
    }
    func create_transactions(transfer_into: Bool, _ cats: CategoriesContext) -> [LedgerEntry]? {
        var result: [LedgerEntry] = [];
        for entry in entries {
            guard let acc = entry.account else { return nil; }
            
            result.append(
                .init(
                    memo: (transfer_into ? "Various to " + acc.name : acc.name + " to Various"),
                    credit: transfer_into ? entry.amount : 0,
                    debit: transfer_into ? 0 : entry.amount,
                    date: Date.now,
                    location: "Bank",
                    category: cats.account_control.transfer,
                    account: acc
                )
            );
        }
        
        return result;
    }
    
    var entries: [ManyTableEntry];
    
    var total: Decimal {
        var sum: Decimal = 0;
        entries.forEach { sum += $0.amount }
        return sum;
    }
}
struct ManyTransferTable : View {
    @Bindable var vm: ManyTransferTableVM;
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    vm.entries.append(
                        ManyTableEntry()
                    )
                }
            }) {
                Label("Add", systemImage: "plus")
            }
        
            Button(action: {
                withAnimation {
                    vm.entries.removeAll(where: { $0.selected })
                }
            }) {
                Label("Remove Selected", systemImage: "trash").foregroundStyle(.red)
            }
            
        }.padding(.top)
        Text("Total: \(vm.total, format: .currency(code: "USD"))")
        
        ScrollView {
            Grid {
                GridRow {
                    Spacer()
                    Text("Amount")
                    Text("Account")

                }
                Divider()
                ForEach($vm.entries) { $item in
                    GridRow {
                        Toggle("Selected", isOn: $item.selected).labelsHidden()
                        TextField("Amount", value: $item.amount, format: .currency(code: "USD")).disabled(item.selected)
                        NamedPairPicker<Account>(target: $item.account).disabled(item.selected)
                    }.background(item.selected ? Color.accentColor.opacity(0.2) : Color.clear)
                }
            }.padding().background(.background.opacity(0.7))
        }
    }
}

#Preview {
    ManyTransferTable(vm: ManyTransferTableVM())
}

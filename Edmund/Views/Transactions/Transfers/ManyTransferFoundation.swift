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
        self.acc = NamedPair(kind: .account);
        self.id = UUID();
        self.selected = false;
    }
    
    
    var amount: Decimal;
    var acc: NamedPair;
    var id: UUID;
    var selected: Bool;
}

@Observable
class ManyTransferTableVM {
    convenience init() {
        self.init(minHeight: 140)
    }
    init(minHeight: CGFloat) {
        entries = [ManyTableEntry()];
        self.minHeight = minHeight;
    }
    
    func clear() {
        entries.forEach { $0.selected = true } //Ensures that no editing happens
        entries = [ManyTableEntry()];
    }
    
    var entries: [ManyTableEntry];
    var minHeight: CGFloat;
    
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
                        NamedPairEditor(acc: $item.acc).disabled(item.selected)
                    }.background(item.selected ? Color.accentColor.opacity(0.2) : Color.clear)
                }.frame(maxHeight: vm.minHeight)
            }.padding().background(.background.opacity(0.7))
        }
    }
}

#Preview {
    ManyTransferTable(vm: ManyTransferTableVM())
}

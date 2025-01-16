//
//  ManualTransactions.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI;
import SwiftData;
import Foundation;

@Observable
class ManTransactionLine : Identifiable {
    init() {
       
    }
    
    var id: UUID = UUID();
    var memo: String = "";
    var credit: Decimal = 0;
    var debit: Decimal = 0;
    var date: Date = Date.now;
    var location: String = "";
    var category: SubCategory? = nil;
    var account: SubAccount? = nil;
    var selected: Bool = false;
    
    func contains_empty() -> Bool {
        memo.isEmpty || category == nil || account == nil
    }
    
    func into_trans() -> LedgerEntry? {
        guard !memo.isEmpty else { return nil }
        guard let acc = self.account, let cat = self.category else { return nil }
        
        return LedgerEntry(
            memo: memo,
            credit: credit,
            debit: debit,
            date: date,
            location: location,
            category: cat,
            account: acc)
    }
}

struct ManTransLineView : View {
    @Binding var line: ManTransactionLine;
    @Binding var enable_dates: Bool;
    
    var body: some View {
        Toggle("Selected", isOn: $line.selected).labelsHidden()
        TextField("Memo", text: $line.memo).frame(minWidth: 120).disabled(line.selected)
        TextField("Money In", value: $line.credit, format: .currency(code: "USD")).frame(minWidth: 60).disabled(line.selected)
        TextField("Money Out", value: $line.debit, format: .currency(code: "USD")).frame(minWidth: 60).disabled(line.selected)
        DatePicker("Date", selection: $line.date, displayedComponents: .date).labelsHidden().disabled(!enable_dates || line.selected)
        TextField("Location", text: $line.location).frame(minWidth: 100).disabled(line.selected)
        NamedPairPicker(target: $line.category).frame(minWidth: 200).disabled(line.selected)
        NamedPairPicker(target: $line.account).frame(minWidth: 200).disabled(line.selected)
    }
}

@Observable
class ManualTransactionsVM : TransViewBase {
    init() {
        adding.append(.init())
    }
    
    var adding : [ManTransactionLine] = [];
    var enable_dates: Bool = true;
    var err_msg: String? = nil;
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        if !validate() { return nil; }
        
        return adding.reduce(into: [:]) {
            guard let acc = $1.account else { return }
            $0[acc.id] = $1.credit - $1.debit
        };
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !validate() { return nil; }
        
        return adding.reduce(into: []) {
            guard let entry = $1.into_trans() else { return }
            $0.append(entry)
        };
    }
    func validate() -> Bool {
        let empty_lines: [Int] = adding.enumerated().reduce(into: []) { result, pair in
            if pair.element.contains_empty() {
                result.append(pair.offset)
            }
        }
        
        if !empty_lines.isEmpty {
            err_msg = "The following lines contain empty fields: " + empty_lines.map(String.init).joined(separator: ", ")
            return false;
        }
        else {
            err_msg = nil;
            return true;
        }
    }
    func clear() {
        adding = []
        err_msg = nil
    }
}

struct ManualTransactions: View {
    @Bindable var vm: ManualTransactionsVM;
    
    private func add_trans() {
        vm.adding.append(.init())
    }
    private func remove_selected() {
        vm.adding.removeAll(where: { $0.selected })
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Manual Transactions").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding([.leading, .trailing], 10).padding(.top, 5)
            
            HStack {
                Button(action: {
                    withAnimation {
                        add_trans()
                    }
                }) {
                    Label("Add", systemImage: "plus")
                }.help("Add a transaction to the table")
                Button(action: {
                    withAnimation {
                        remove_selected()
                    }
                }) {
                    Label("Remove Selected", systemImage: "trash").foregroundStyle(.red)
                }.help("Remove all transactions that are currently selected")
            }.padding(.bottom, 5)
            
            Toggle("Enable Dates", isOn: $vm.enable_dates).help("Enable the date field, for manual input. You can disable the date field for quicker inputs if the current date is satisfactory.")
            
            ScrollView {
                Grid {
                    GridRow {
                        Text("")
                        Text("Memo")
                        Text("Credit")
                        Text("Debit")
                        Text("Date")
                        Text("Location")
                        Text("Category")
                        Text("Account")
                    }
                    Divider()
                    
                    ForEach($vm.adding) { $item in
                        GridRow {
                            ManTransLineView(line: $item, enable_dates: $vm.enable_dates)
                        }
                    }
                }.padding().background(.background.opacity(0.7))
            }
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ManualTransactions(vm: .init())
}

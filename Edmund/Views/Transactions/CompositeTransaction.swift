//
//  CompositeTransaction.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI;
import Foundation;

@Observable
class CompositeTransactionVM : TransViewBase {
    init() {
        
    }
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        if !validate() { return nil }
        guard let acc = self.acc else { return nil }
        
        return [acc.id: credit ? total : -total];
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !validate() { return nil }
        
        guard let acc = self.acc, let cat = self.category else { return nil }
        
        return [
            .init(
                memo: memo,
                credit: self.credit ? total : 0,
                debit: self.credit ? 0 : total,
                date: self.date,
                location: location,
                category: cat,
                account: acc)
        ]
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
        
        if memo.isEmpty { empty_fields.append("memo") }
        if category == nil { empty_fields.append("category") }
        if acc == nil { empty_fields.append("account")}
        
        if !empty_fields.isEmpty {
            err_msg = "The following fields are empty: " + empty_fields.joined(separator: ", ");
            return false;
        }
        else {
            err_msg = nil;
            return true;
        }
    }
    func clear() {
        memo = "";
        date = Date.now;
        location = "Various";
        category = nil
        acc = nil
        entries = [];
        credit = false;
        err_msg = nil;
    }
    
    var memo: String = ""
    var date: Date = Date.now
    var location: String = "Various"
    var category: SubCategory? = nil
    var acc: SubAccount? = nil
    var entries: [Decimal] = [];
    var credit: Bool = false;
    var err_msg: String? = nil;
    
    var total: Decimal {
        entries.reduce(into: 0.0) { $0 += $1 }
    }
}

struct CompositeTransaction : View {
    @Bindable var vm: CompositeTransactionVM;
    
    var body : some View {
        VStack {
            HStack {
                Text("Composite Transaction").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            Grid {
                GridRow {
                    Text("Memo")
                    TextField("Memo", text: $vm.memo)
                }
                GridRow {
                    Text("Date")
                    HStack {
                        DatePicker("", selection: $vm.date, displayedComponents: .date).labelsHidden()
                        Text("Location")
                        TextField("Location", text: $vm.location)
                    }
                }
                GridRow {
                    Text("Category")
                    NamedPairPicker<Category>(target: $vm.category)
                }
                GridRow {
                    Text("Account")
                    NamedPairPicker<Account>(target: $vm.acc)
                }
            }.padding(.bottom, 5)
            
            HStack {
                Button(action: {}) {
                    Label("Add", systemImage: "plus")
                }
                Button(action: {}) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }
            }
            
            ScrollView {
                Grid {
                    /*
                    let upper_bound: Int = .init(
                        ceil(Double.init(vm.entries.count) / 4.0)
                    )
                    
                    ForEach(vm.entries.windows(ofSize: 4)) { group in
                        GridRow {
                            ForEach(group) { item in
                                Text("Here")
                            }
                        }
                    }
                    ForEach(0..<upper_bound, id: \Int.self) { row_index in
                        GridRow {
                            ForEach(row_index..<(row_index * 4)) {
                                Text("\($0, format: .currency(code: "USD"))")
                            }
                        }
                    }
                    */
                }
            }.frame(minHeight: 120)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    CompositeTransaction(vm: CompositeTransactionVM())
}

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
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        if !validate() { return nil }
        
        return [acc: credit ? total : -total];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil }
        
        return [
            LedgerEntry(memo: memo, credit: self.credit ? total : 0, debit: self.credit ? 0 : total, date: self.date, location: location, category_pair: category, account_pair: acc)
        ]
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
        
        if memo.isEmpty { empty_fields.append("memo") }
        if category.isEmpty { empty_fields.append("category") }
        if acc.isEmpty { empty_fields.append("account")}
        
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
        category = NamedPair(kind: .category);
        acc = NamedPair(kind: .account);
        entries = [];
        credit = false;
        err_msg = nil;
    }
    
    var memo: String = ""
    var date: Date = Date.now
    var location: String = "Various"
    var category: NamedPair = NamedPair(kind: .category)
    var acc: NamedPair = NamedPair(kind: .account)
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
                    NamedPairEditor(acc: $vm.category)
                }
                GridRow {
                    Text("Account")
                    NamedPairEditor(acc: $vm.acc)
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
                VStack {
                    
                }
            }.frame(minHeight: 120)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    CompositeTransaction(vm: CompositeTransactionVM())
}

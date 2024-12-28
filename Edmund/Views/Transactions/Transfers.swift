//
//  Transfers.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI

class OneOneTransferVM : ObservableObject, TransViewBase {
    func compile_deltas() -> Dictionary<AccountPair, Decimal> {
        return [:];
    }
    func create_transactions() -> [LedgerEntry]? {
        return [];
    }
    func validate() -> Bool {
        return false;
    }
    func clear() {
        err_msg = nil;
        amount = 0;
        src = AccountPair(account: "", sub_account: "");
        dest = AccountPair(account: "", sub_account: "");
    }
    
    
    @Published var err_msg: String? = nil;
    @Published var amount: Decimal = 0.0;
    @Published var src: AccountPair = AccountPair(account: "", sub_account: "");
    @Published var dest: AccountPair = AccountPair(account: "", sub_account: "");
}

class MOOMEntry: Identifiable {
    
    var amount: Decimal = 0.0;
    var acc: AccountPair = AccountPair(account: "", sub_account: "");
    var id: UUID = UUID();
}

class ManyCoreVM : ObservableObject {
    init() {
        
    }
    init(amount: Binding<Decimal>) {
        self.amount = amount;
    }
    
    func clear() {
        if amount != nil {
            amount!.wrappedValue = 0.0;
        }
        rem_acc = AccountPair(account: "", sub_account: "");
        breakdowns = [];
        err_msg = nil;
    }
    
    @Published var amount: Binding<Decimal>? = nil;
    @Published var rem_acc: AccountPair = AccountPair(account: "", sub_account: "")
    @Published var breakdowns: [PaydayBreakdown] = [];
    @Published var err_msg: String? = nil;
    
    var total: Decimal {
        var sum: Decimal = 0;
        breakdowns.forEach { sum += $0.amount }
        return sum;
    }
    var remainder: Decimal? {
        if let amt = amount {
            return amt.wrappedValue - total;
        }
        else {
            return nil;
        }
    }
}
struct ManyCore : View {
    
    @ObservedObject var vm: ManyCoreVM;
    @State var selected: UUID? = nil;
    
    private func amount_field(item_kind: BreakdownKind, binding: Binding<PaydayBreakdown>) -> some View {
        switch item_kind {
        case .percent:
            TextField("Percent", value: binding.amount, format: .percent)
        case .simple:
            TextField("Amount", value: binding.amount, format: .currency(code: "USD"))
        }
    }
    
    var body: some View {
        /*
         HStack {
             Button(action: {
                 vm.subs.append(MOOMEntry())
             }) {
                 Label("Add", systemImage: "plus")
             }
             Button(action: {
                 if selected == nil { return }
                 
                 vm.subs.removeAll(where: { $0.id == selected })
             }) {
                 Label("Remove", systemImage: "trash").foregroundStyle(.red).disabled(selected == nil)
             }
         }
         
         Table($vm.subs, selection: $selected) {
             TableColumn("Amount") { $item in
                 TextField("Amount", value: $item.amount, format: .currency(code: "USD"))
             }
             TableColumn("Account") { $item in
                 TextField("Account", text: $item.acc.account)
             }
             TableColumn("Sub Account") { $item in
                 TextField("Sub Account", text: $item.acc.sub_account)
             }
         }.frame(minHeight: 140)
         */
        
        HStack {
            Button(action: {
                vm.breakdowns.append(
                    PaydayBreakdown(account_name: "", kind: .simple)
                )
            }) {
                Label("Add Simple", systemImage: "plus")
            }.help("Add a breakdown that takes a specific amount from the pay")
            Button(action: {
                vm.breakdowns.append(
                    PaydayBreakdown(account_name: "", kind: .percent)
                )
            }) {
                Label("Add Percentage", systemImage: "percent")
            }.help("Add a breakdown that takes a percentage of the pay")
            
            Button(action: {
                if selected == nil { return }
                
                vm.breakdowns.removeAll(where: { $0.id == selected })
            }) {
                Label("Remove", systemImage: "trash").foregroundStyle(.red).disabled(selected == nil)
            }.help("")
        }
        HStack {
            if vm.amount != nil {
                Text("Total: \(vm.total, format: .currency(code: "USD"))")
                Text("Remaining: \(vm.remainder!, format: .currency(code: "USD"))")
            } else {
                Text("Total: \(vm.total)")
            }
        }
        
        Table($vm.breakdowns, selection: $selected) {
            TableColumn("Amount") { $item in
                amount_field(item_kind: item.kind, binding: $item)
            }
            TableColumn("Account") { $item in
                TextField("Account", text: $item.acc.account)
            }
            TableColumn("Sub Account") { $item in
                TextField("Sub Account", text: $item.acc.sub_account)
            }
        }.frame(minHeight: 140)
    }
}

class OneManyTransferVM : ObservableObject, TransViewBase {
    init() {
        multi = ManyCoreVM(amount: Binding<Decimal>(
            get: {
                self.amount
            },
            set: { v in
                self.amount = v;
            }
        ));
    }
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal> {
        return [:];
    }
    func create_transactions() -> [LedgerEntry]? {
        return [];
    }
    func validate() -> Bool {
        return false;
    }
    func clear() {
        err_msg = nil;
        amount = 0;
        acc = AccountPair(account: "", sub_account: "");
        multi.clear();
    }
     
    @Published var err_msg: String? = nil;
    @Published var amount: Decimal = 0.0;
    @Published var acc: AccountPair = AccountPair(account: "", sub_account: "");
    @ObservedObject var multi: ManyCoreVM = ManyCoreVM();
}

struct OneOneTransfer : View {
    
    @ObservedObject var vm: OneOneTransferVM;
    
    var body: some View {
        VStack {
            HStack {
                Text("One-to-One Transfer").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)

            Grid() {
                GridRow {
                    Text("Take")
                    TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                }
                   
                GridRow {
                    Text("From")
                    AccPair(acc: $vm.src)
                }
                
                GridRow {
                    Text("Into")
                    AccPair(acc: $vm.dest)
                }
                
            }.padding(.bottom, 10).frame(minWidth: 300, maxWidth: .infinity)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

struct OneManyTransfer : View {
    
    @ObservedObject var vm: OneManyTransferVM;
    @State private var selected: UUID?;
    
    var body: some View {
        VStack {
            HStack {
                Text("One-to-Many Transfer").font(.headline)
                
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            Grid() {
                GridRow {
                    Text("Take")
                    TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                }
                GridRow {
                    Text("From")
                    AccPair(acc: $vm.acc)
                }
            }
            
            HStack {
                Text("Release into")
                Spacer()
            }
            
            ManyCore(vm: vm.multi)
            
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ScrollView {
        VStack {
            OneOneTransfer(vm: OneOneTransferVM())
            OneManyTransfer(vm: OneManyTransferVM())
        }.padding()
    }
}

//
//  Transfers.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI

class OneOneTransferVM : ObservableObject {
    
    @Published var err_msg: String? = nil;
    @Published var amount: Decimal = 0.0;
    @Published var src: AccountPair = AccountPair(account: "", sub_account: "");
    @Published var dest: AccountPair = AccountPair(account: "", sub_account: "");
}

enum MOOMKind {
    case one_many
    case many_one
}
class MOOMEntry : Identifiable {
    
    var amount: Decimal = 0.0;
    var acc: AccountPair = AccountPair(account: "", sub_account: "");
    var id: UUID = UUID();
}
class MOOMTransferVM : ObservableObject {
    init(mode: MOOMKind) {
        self.mode = mode;
    }
     
    @Published var err_msg: String? = nil;
    @Published var amount: Decimal = 0.0;
    @Published var acc: AccountPair = AccountPair(account: "", sub_account: "");
    @Published var subs: [MOOMEntry] = [];
    @Published var mode: MOOMKind;
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

            LazyVGrid(columns: [GridItem(.fixed(33)), GridItem()]) {
                Text("Take")
                TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                
                Text("From")
                AccPair(acc: $vm.src)
                
                Text("Into")
                AccPair(acc: $vm.dest)
                
            }.padding(.bottom, 10).frame(minWidth: 300, maxWidth: .infinity)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

struct MOOMTransfer : View {
    
    @ObservedObject var vm: MOOMTransferVM;
    
    private func make_one(is_debit: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.fixed(47)), GridItem()]) {
            if is_debit {
                Text("Take")
            }
            else {
                Text("Deposit")
            }
            
            TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
            
            if is_debit {
                Text("From")
            }
            else {
                Text("Into")
            }
            
            AccPair(acc: $vm.acc)
        }.padding(.bottom)
    }
    
    var body: some View {
        VStack {
            HStack {
                if vm.mode == .one_many {
                    Text("One-to-Many Transfer").font(.headline)
                }
                else {
                    Text("Many-to-One Transfer").font(.headline)
                }
                
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            Picker("Mode", selection: $vm.mode) {
                Text("One-to-Many").tag(MOOMKind.one_many)
                Text("Many-to-One").tag(MOOMKind.many_one)
            }.padding(.bottom, 7)
            
            Divider()
            
            if vm.mode == .one_many {
                make_one(is_debit: true)
                HStack {
                    Text("Deposit to")
                    Spacer()
                }.padding([.bottom])
            }
            else {
                HStack {
                    Text("Take from")
                    Spacer()
                }
                
                make_one(is_debit: false)
            
            }
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    MOOMTransfer(vm: MOOMTransferVM(mode: .one_many))
}

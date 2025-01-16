//
//  BillPayment.swift
//  Edmund
//
//  Created by Hollan on 1/16/25.
//

import SwiftUI
import SwiftData

@Observable
class BillPaymentVM : TransViewBase {
    init() {
        
    }
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        return [:]
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        return []
    }
    func validate() -> Bool {
        err_msg = "This view does not produce anything right now, no error occured.";
        return true
    }
    func clear() {
        err_msg = nil;
    }
    
    var err_msg: String? = nil;
}

struct BillPayment : View {
    @Bindable var vm: BillPaymentVM;
    
    var body: some View {
        VStack {
            HStack {
                Text("Payment").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundColor(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            Text("This is still in progress, and is not avalible right now.").italic().bold().padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    BillPayment(vm: .init())
}

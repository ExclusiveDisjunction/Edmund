//
//  PersonLoan.swift
//  Edmund
//
//  Created by Hollan on 1/16/25.
//

import SwiftUI
import SwiftData

@Observable
class PersonalLoanTransVM : TransViewBase {
    init() {
        
    }
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        guard validate() else { return nil }
        guard let acc = account else { return nil }
        
        return [acc.id : loaning ? -amount : amount ];
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        guard validate() else { return nil }
        guard let acc = account else { return nil }
        
        return [
            .init(
                memo: loaning ? "Loan to '\(person)'" : "Repayment from '\(person)'",
                credit: loaning ? 0 : amount,
                debit: loaning ? amount : 0,
                date: self.date,
                location: "Bank",
                category: loaning ? cats.payments.loan : cats.payments.repayment,
                account: acc
            )
        ]
    }
    func validate() -> Bool {
        let acc_empty = account == nil;
        let person_empty = person.isEmpty;
        
        if acc_empty && person_empty {
            err_msg = "The account and person is empty"
        }
        else if acc_empty {
            err_msg = "The account is empty"
        }
        else if person_empty {
            err_msg = "The person is empty"
        }
        else {
            err_msg = nil
        }
        
        return err_msg != nil
    }
    func clear() {
        account = nil
        person = ""
        amount = 0.00
        loaning = true
        err_msg = nil
        date = Date.now
        show_date = false
    }
    
    var account: SubAccount? = nil
    var person: String = "";
    var amount: Decimal = 0.00;
    var loaning: Bool = true;
    var date: Date = Date.now;
    var show_date: Bool = false;
    var err_msg: String? = nil
}

struct PersonalLoanTrans : View {
    @Bindable var vm: PersonalLoanTransVM;
    
    //Loan: [Person] (got/repayed) $[Amount]
    
    var body: some View {
        VStack {
            HStack {
                Text("Payment").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundColor(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            Toggle("Manual Date", isOn: $vm.show_date)
            
            VStack {
                HStack {
                    TextField("Person", text: $vm.person)
                    HStack {
                        Button( action: {
                            vm.loaning = true
                        }) {
                            Text("Got").foregroundStyle(vm.loaning ? Color.accentColor : Color.primary)
                            
                        }
                        
                        Button(action: {
                            vm.loaning = false
                        }) {
                            Text("Repayed").foregroundStyle(vm.loaning ? Color.primary : Color.accentColor)
                        }
                    }
                }
                
                HStack {
                    Text("Amount")
                    TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                }
                
                HStack {
                    if vm.loaning {
                        Text("From")
                    } else {
                        Text("Into")
                    }
                    NamedPairPicker(target: $vm.account, child_default: "Loan")
                }
                
                if vm.show_date {
                    DatePicker("Date", selection: $vm.date, displayedComponents: .date).frame(maxWidth: .infinity)
                }
            }.padding(.bottom, 5)
            
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    PersonalLoanTrans(vm: .init())
}

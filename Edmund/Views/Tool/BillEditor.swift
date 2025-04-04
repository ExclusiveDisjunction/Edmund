//
//  BillEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

struct BillEditor : View {
    @Bindable var bill: Bill;
    @Environment(\.dismiss) private var dismiss;
    @State private var nameRed = false;
    @State private var showAlert = false;
    
    private func check_dismiss() -> Bool {
        if bill.name.isEmpty {
            showAlert = true;
            nameRed = true;
            return false;
        }
        else {
            return true;
        }
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $bill.name)
                    TextField("Amount", value: $bill.amount, format: .currency(code: "USD"))
                    Picker("Frequency", selection: $bill.period) {
                        ForEach(BillsPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Ok") {
                    if check_dismiss() {
                        dismiss()
                    }
                }.buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please ensure that the name is not empty.")
        })
    }
}

#Preview {
    let bill = Bill.exampleBills[0]
    
    BillEditor(bill: bill).modelContainer(Containers.debugContainer)
}

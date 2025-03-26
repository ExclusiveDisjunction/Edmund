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
            Grid {
                GridRow {
                    Text("Name")
                    TextField("Name", text: $bill.name)
                }
                
                GridRow {
                    Text("Amount")
                    TextField("Amount", value: $bill.amount, format: .currency(code: "USD"))
                }
                
                GridRow {
                    Text("Fequency")
                    Picker("Frequency", selection: $bill.period) {
                        Text("Weekly").tag(BillsPeriod.weekly)
                        Text("Monthly").tag(BillsPeriod.monthly)
                        Text("Quarter-annually").tag(BillsPeriod.triMonthly)
                        Text("Semi-annually").tag(BillsPeriod.hexMonthly)
                        Text("Annually").tag(BillsPeriod.anually)
                    }.labelsHidden()
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
    var bill = Bill(name: "Test", amount: 40, kind: .simple, period: .monthly)
    
    BillEditor(bill: bill).modelContainer(ModelController.previewContainer)
}

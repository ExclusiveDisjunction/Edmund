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
                    if !nameRed {
                        TextField("Name", text: $bill.name)
                    }
                    else {
                        TextField("Name", text: $bill.name).border(Color.red)
                    }
                }
                
                GridRow {
                    Text("Amount")
                    TextField("Amount", value: $bill.amount, format: .currency(code: "USD"))
                }
                
                GridRow {
                    Text("Fequency")
                    Picker("Frequency", selection: $bill.period) {
                        ForEach(BillsPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
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
    let bill = Bill(name: "Test", amount: 40, kind: .subscription, period: .monthly)
    
    BillEditor(bill: bill).modelContainer(ModelController.previewContainer)
}

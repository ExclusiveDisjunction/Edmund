//
//  Homepage.swift
//  Edmund
//
//  Created by Hollan on 1/1/25.
//

import SwiftUI;

struct Homepage : View {
    
    var body: some View {
        VStack {
            VStack {
                Image("IconUI").resizable().scaledToFit().frame(width: 128, height: 128)
                Text("Welcome to Edmund!").font(.title)
                Text("Personal Budgeting Software").font(.subheadline)
            }.padding()
            Divider()
            VStack {
                Text("Topics").font(.title2).padding()
                Grid {
                    GridRow {
                        Text("Ledger").font(.headline)
                        Text("Transactions").font(.headline)
                        Text("Balance Sheet").font(.headline)
                    }.frame(maxWidth: .infinity)
                    GridRow {
                        Text("Review all transactions").multilineTextAlignment(.center)
                        Text("Add to the ledger to update balances").multilineTextAlignment(.center)
                        Text("Review the credits, debits, and balances of all accounts & sub accounts").multilineTextAlignment(.center)
                    }.padding(.bottom).frame(maxWidth: .infinity, maxHeight: 70)
                    GridRow {
                        Text("Accounts & Categories").font(.headline)
                        Text("Paychecks").font(.headline)
                        Text("Bills").font(.headline)
                    }.frame(maxWidth: .infinity)
                    GridRow {
                        Text("Add and modify accounts & categories").multilineTextAlignment(.center)
                        Text("Record and review paychecks").multilineTextAlignment(.center)
                        Text("Add, modify, and remove bills").multilineTextAlignment(.center)
                    }.padding(.bottom).frame(maxWidth: .infinity, maxHeight: 70)
                    GridRow {
                        Text("Budget").font(.headline)
                        Text("")
                        Text("Management").font(.headline)
                    }.frame(maxWidth: .infinity)
                    GridRow {
                        Text("Update and determine the budget").multilineTextAlignment(.center)
                        Text("")
                        Text("Modify all data stored and resetting the ledger").multilineTextAlignment(.center)
                    }.padding(.bottom).frame(maxWidth: .infinity, maxHeight: 70)
                }
            }.padding()
        }.frame(minHeight: 550)
            .navigationTitle("Edmund")
    }
}

#Preview {
    Homepage()
}

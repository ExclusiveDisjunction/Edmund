//
//  BalanceVerification.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

struct BalanceVerifyRow : Identifiable {
    
    var id: UUID = UUID()
    @State var name: String;
    @State var balance: Double;
    @State var creditLimit: Double;
    @State var expectedBalance: Double;
    
    var variance: Double {
        balance - expectedBalance
    }
}

struct BalanceVerification: View {
    @Query(filter: #Predicate<Account> { $0.creditLimit != nil }) private var accounts: [Account];
    @Query private var transactions: [LedgerEntry];
    @State private var manual: Bool = false;
    @State private var rows: [BalanceVerifyRow] = [];
    
    private func refresh() {
        
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Balance Verification").font(.title)
                Spacer()
            }
            
            HStack {
                Button(action: refresh) {
                    Label("Refresh", systemImage: "arrow.2.circlepath.circle")
                }
                Button(action: {
                    manual.toggle()
                }) {
                    Label(manual ? "Calculated" : "Manual", systemImage: manual ? "plus.slash.minus" : "pencil")
                }
            }.padding(.bottom)
            
            if !rows.isEmpty {
                Grid {
                    GridRow {
                        Text("Accout Name")
                        Text("Credit Limit")
                        Text("Current Balance")
                        Text("Expected Balance")
                        Text("Variance")
                    }
                }
            }
            else {
                Text("There is nothing to report")
                Text("Please add at least one account with a credit limit")
                Text("If results are not being updated, press refresh").italic()
            }
        }.padding().task { refresh() }
    }
}

#Preview {
    BalanceVerification().modelContainer(ModelController.previewContainer)
}

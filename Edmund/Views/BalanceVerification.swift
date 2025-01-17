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
    @State var avalibleCredit: Decimal;
    @State var creditLimit: Decimal;
    @State var balance: Decimal;
    
    var expectedBalance: Decimal {
        creditLimit - avalibleCredit
    }
    var variance: Decimal {
        balance - expectedBalance
    }
}

struct BalanceVerification: View {
    @Query private var transactions: [LedgerEntry];
    @State private var manual: Bool = false;
    @State private var rows: [BalanceVerifyRow] = [];
    
    private func refresh() {
        let bals = BalanceResolver.compileBalancesAccounts(transactions).filter { $0.key.creditLimit != nil };
        
        rows = bals.reduce(into: []) {
            $0.append(
                BalanceVerifyRow(
                    name: $1.key.name,
                    avalibleCredit: $1.key.creditLimit!, //Already checked with filter, default is credit limit
                    creditLimit: $1.key.creditLimit!, //Already checked with filter
                    balance: $1.value.0 - $1.value.0
                 )
            )
        }
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
                        Text("Avalible Credit")
                        Text("Credit Limit")
                        Text("Current Balance")
                        Text("Expected Balance")
                        Text("Variance")
                    }
                    Divider()
                    ForEach($rows) { $item in
                        GridRow {
                            Text("\(item.name)")
                            TextField("Amount", value: $item.avalibleCredit, format: .currency(code: "USD"))
                            Text("\(item.creditLimit, format: .currency(code: "USD"))")
                            Text("\(item.balance, format: .currency(code: "USD"))")
                            Text("\(item.expectedBalance, format: .currency(code: "USD"))")
                            Text("\(item.variance, format: .currency(code: "USD"))")
                        }
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

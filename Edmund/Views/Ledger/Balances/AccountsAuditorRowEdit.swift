//
//  BalanceVerifyRowEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/4/25.
//

import SwiftUI
import EdmundCore

@Observable
class AccountsAuditorRow : Identifiable {
    init(account: Account, balance: Decimal) {
        self.id = UUID();
        self.account = account;
        self.balance = balance
        self.expectedBalance = .init(rawValue: balance)
    }
    
    let id: UUID
    let account: Account;
    var name: String {
        account.name
    }
    var expectedBalance: CurrencyValue;
    let balance: Decimal;
    
    var variance: Decimal {
        balance - expectedBalance.rawValue
    }
    var absVariance : Decimal {
        abs(balance) - abs(expectedBalance.rawValue)
    }
}

struct AccountsAuditorRowEdit : View {
    @Bindable var over: AccountsAuditorRow;
    let isSheet: Bool;
    
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 115;
    private let maxWidth: CGFloat = 120;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(over.name)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Expected Balance:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(over.expectedBalance)
                }
                
                GridRow {
                    Text("Current Balance:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(over.balance, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Variance:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(over.variance, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Status:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        BalanceStatusText(data: over.variance)
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            if isSheet {
                HStack {
                    Spacer()
                    Button("Ok", action: { dismiss() } )
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

#Preview {
    let object = AccountsAuditorRow(account: Account.exampleAccount, balance: 15)
    AccountsAuditorRowEdit(over: object, isSheet: false)
        .padding()
}

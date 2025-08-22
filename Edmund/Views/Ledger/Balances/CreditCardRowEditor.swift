//
//  Balance.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/4/25.
//

import SwiftUI
import EdmundCoreImm

@Observable
class CreditCardRow : Identifiable {
    init(account: Account, balance: Decimal) {
        self.id = UUID();
        self.account = account;
        let rawBalance = balance + (account.creditLimit ?? .nan);
        self.avalibleCredit = .init(rawValue: rawBalance);
        self.balance = balance
    }
    
    let id: UUID
    let account: Account;
    var name: String {
        account.name
    }
    var avalibleCredit: CurrencyValue;
    var creditLimit: Decimal {
        account.creditLimit ?? .nan
    }
    let balance: Decimal;
    
    var expectedBalance: Decimal {
        avalibleCredit.rawValue - creditLimit
    }
    var variance: Decimal {
        expectedBalance - balance
    }
}

struct CreditCardRowEditor : View {
    @Bindable var over: CreditCardRow;
    let isSheet: Bool;
    
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 115;
    private let maxWidth: CGFloat = 120;
#else
    private let minWidth: CGFloat = 120;
    private let maxWidth: CGFloat = 130;
#endif
    
    
    var body: some View {
        VStack {
            HStack {
                Text("Credit Card Audit Close Look")
                    .font(.title2)
                
                Spacer()
            }.padding(.bottom)
            
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
                    Text("Credit Limit:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(over.creditLimit, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Availiable Limit:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(over.avalibleCredit)
                }
                
                GridRow {
                    Text("Expected Balance:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(over.expectedBalance, format: .currency(code: currencyCode))
                        Spacer()
                    }
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
    let data = CreditCardRow(account: Account.exampleCreditAccount, balance: -15.00);
    
    CreditCardRowEditor(over: data, isSheet: true)
        .padding()
}

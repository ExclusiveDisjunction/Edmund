//
//  AccountInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import SwiftUI
import SwiftData
import EdmundCore

/// The inspect view for Account.
public struct AccountInspect : View {
    public init(_ data: Account) {
        self.data = data;
    }
    
    private var data: Account;
    @State private var showSubAccounts = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 90;
#else
    private let labelMinWidth: CGFloat = 100;
    private let labelMaxWidth: CGFloat = 110;
#endif
    
    public var body: some View {
        ScrollView {
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.name)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Kind:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.kind.display)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Credit Limit:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if let creditLimit = data.creditLimit {
                            Text(creditLimit, format: .currency(code: currencyCode))
                        }
                        else {
                            Text("No credit limit")
                                .italic()
                        }
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Interest:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if let interest = data.interest {
                            Text(interest, format: .percent.precision(.fractionLength(3)))
                        }
                        else {
                            Text("No interest")
                                .italic()
                        }
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Location:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if let location = data.location {
                            Text(location)
                        }
                        else {
                            Text("No location")
                                .italic()
                        }
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("")
                    
                    HStack {
                        Button("Sub Accounts") {
                            showSubAccounts = true;
                        }
                        Spacer()
                    }
                    
                }
            }.sheet(isPresented: $showSubAccounts) {
                SubAccountsInspect(children: data.children)
                    .padding()
            }
        }
    }
}

#Preview {
    ElementInspector(data: Account.exampleAccount)
}

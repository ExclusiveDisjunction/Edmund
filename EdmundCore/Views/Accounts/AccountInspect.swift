//
//  AccountInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import SwiftUI
import SwiftData

/// The inspect view for Account.
public struct AccountInspect : View, ElementInspectorView {
    public typealias For = Account
    
    public init(_ data: Account) {
        self.data = data;
    }
    
    private var data: Account;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @State private var selectedChild: String?;
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 90;
#else
    private let labelMinWidth: CGFloat = 100;
    private let labelMaxWidth: CGFloat = 110;
#endif
    
    public var body: some View {
        ScrollView {
            VStack {
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
                    
                    if data.children != nil {
                        Divider()
                        
                        GridRow {
                            Text("Sub Accounts:")
                                .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                            
                            Text("")
                        }
                    }
                }
                
                if let children = data.children {
                    Table(children, selection: $selectedChild) {
                        TableColumn("Name", value: \.name)
                    }
                    .frame(minHeight: 200)
                }
            }
        }
    }
}

#Preview {
    ElementInspector(data: Account.exampleAccount)
        .modelContainer(Containers.debugContainer)
}

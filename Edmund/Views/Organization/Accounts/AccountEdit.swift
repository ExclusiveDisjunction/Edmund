//
//  AccountEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import SwiftUI
import SwiftData

/// The edit view for Account.
public struct AccountEdit : View {
    public init(_ data: AccountSnapshot) {
        self.snapshot = data
    }
    
    @Bindable private var snapshot: AccountSnapshot;
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 90;
#else
    private let labelMinWidth: CGFloat = 100;
    private let labelMaxWidth: CGFloat = 110;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Name:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                TextField("Name", text: $snapshot.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                Picker("", selection: $snapshot.kind) {
                    ForEach(AccountKind.allCases, id: \.id) { kind in
                        Text(kind.display)
                            .id(kind)
                    }
                }
                .labelsHidden()
            }
            
            if snapshot.hasCreditLimit {
                GridRow {
                    Text("Credit Limit:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    CurrencyField(snapshot.creditLimit)
                }
            }
            
            GridRow {
                Text("Has Interest:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Toggle("", isOn: $snapshot.hasInterest)
                        .labelsHidden()
                    
                    Spacer()
                }
            }
            
            if snapshot.hasInterest {
                GridRow {
                    Text("Interest:", comment: "Money interest")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    TextField("", value: $snapshot.interest, format: .percent.precision(.fractionLength(3)))
                }
            }
            
            GridRow {
                Text("Has Location:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Toggle("", isOn: $snapshot.hasLocation)
                        .labelsHidden()
                    
                    Spacer()
                }
            }
            
            if snapshot.hasLocation {
                GridRow {
                    Text("Location:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    TextField("Location", text: $snapshot.location)
                }
            }
        }
    }
}

#Preview {
    ElementEditor(Account(), adding: false)
        .modelContainer(Containers.debugContainer)
}

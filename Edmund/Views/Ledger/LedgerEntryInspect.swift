//
//  LedgerEntryVE.swift
//  Edmund
//
//  Created by Hollan on 4/1/25.
//

import SwiftUI
import SwiftData
import EdmundCore

/// The inspect view for Ledger Entries.
public struct LedgerEntryInspect : View {
    public init(_ data: LedgerEntry) {
        self.target = data;
    }
    
    public let target: LedgerEntry;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    public let labelMinWidth: CGFloat = 60;
    public let labelMaxWidth: CGFloat = 70;
#else
    public let labelMinWidth: CGFloat = 90;
    public let labelMaxWidth: CGFloat = 95;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Memo:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(target.name)
                    Spacer()
                }
            }
            GridRow {
                Text(ledgerStyle == .none ? "Money In:" : ledgerStyle == .standard ? "Debit:" : "Credit:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(target.credit, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            GridRow {
                Text(ledgerStyle == .none ? "Money Out:" : ledgerStyle == .standard ? "Credit:" : "Debit:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(target.debit, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            GridRow {
                Text("Balance:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(target.balance, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Date:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(target.date.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                }
            }
            GridRow {
                Text("Added On:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(target.addedOn.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Location:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(target.location)
                    Spacer()
                }
            }

            GridRow {
                Text("Category:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    if let cat = target.category {
                        CompactNamedPairInspect(cat)
                    }
                    else {
                        Text("No Category")
                    }
                    
                    Spacer()
                }
            }
            GridRow {
                Text("Account:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    if let acc = target.account {
                        CompactNamedPairInspect(acc)
                    }
                    else {
                        Text("No Account")
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    DebugContainerView {
        ElementInspector(data: LedgerEntry.exampleEntry)
    }
}

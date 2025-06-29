//
//  LedgerEntryEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

/// The edit view for Ledger Entries.
public struct LedgerEntryEdit : View {
    public init(_ data: LedgerEntrySnapshot) {
        self.snapshot = data;
    }
    
    @Bindable private var snapshot : LedgerEntrySnapshot;
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 70;
    private let labelMaxWidth: CGFloat = 80;
#else
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 90;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Memo:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                TextField("Name", text: $snapshot.name).textFieldStyle(.roundedBorder)
            }
            GridRow {
                Text(ledgerStyle == .none ? "Money In:" : ledgerStyle == .standard ? "Debit:" : "Credit:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    TextField("Credit", value: $snapshot.credit, format: .currency(code: currencyCode))
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                    
                    Spacer()
                }
            }
            GridRow {
                Text(ledgerStyle == .none ? "Money Out:" : ledgerStyle == .standard ? "Credit:" : "Debit:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    TextField("Debit", value: $snapshot.debit, format: .currency(code: currencyCode))
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                    
                    Spacer()
                }
            }
            GridRow {
                Text("Balance:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(snapshot.balance, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Date:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("Date", selection: $snapshot.date, displayedComponents: .date).labelsHidden()
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Location:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    TextField("Location", text: $snapshot.location).textFieldStyle(.roundedBorder)
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Category:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    NamedPairPicker($snapshot.category)
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Account:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    NamedPairPicker($snapshot.account)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ElementEditor(LedgerEntry.exampleEntry, adding: false)
        .modelContainer(Containers.debugContainer)
}

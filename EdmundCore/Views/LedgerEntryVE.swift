//
//  LedgerEntryVE.swift
//  Edmund
//
//  Created by Hollan on 4/1/25.
//

import SwiftUI
import SwiftData

public struct LedgerEntryEdit : ElementEditorView {
    public typealias For = LedgerEntry;
    
    public init(_ data: LedgerEntrySnapshot) {
        self.snapshot = data;
    }
    
    @Bindable private var snapshot : LedgerEntrySnapshot;
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 60;
    private let labelMaxWidth: CGFloat = 70;
#else
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 85;
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
                    TextField("Credit", value: $snapshot.credit, format: .currency(code: currencyCode)).textFieldStyle(.roundedBorder)
                    Spacer()
                }
            }
            GridRow {
                Text(ledgerStyle == .none ? "Money Out:" : ledgerStyle == .standard ? "Credit:" : "Debit:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    TextField("Debit", value: $snapshot.debit, format: .currency(code: currencyCode)).textFieldStyle(.roundedBorder)
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
public struct LedgerEntryInspect : ElementInspectorView {
    public typealias For = LedgerEntry;
    
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
    public let labelMinWidth: CGFloat = 80;
    public let labelMaxWidth: CGFloat = 85;
#endif
    
    public var body: some View {
        Grid {
            if ledgerStyle != .none {
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
                    Text(target.added_on.formatted(date: .abbreviated, time: .shortened))
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
            Divider()
            GridRow {
                Text("Category:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    if let cat = target.category {
                        NamedPairViewer(cat)
                    }
                    else {
                        Text("No Category")
                    }
                    
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Account:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    if let acc = target.account {
                        NamedPairViewer(acc)
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

public typealias LedgerEntryIE = ElementIE<LedgerEntry>;

#Preview {
    LedgerEntryIE(LedgerEntry.exampleEntry, isEdit: true).modelContainer(Containers.debugContainer)
}

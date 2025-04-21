//
//  LedgerEntryVE.swift
//  Edmund
//
//  Created by Hollan on 4/1/25.
//

import SwiftUI
import SwiftData

struct LedgerEntryEdit : ElementEditView {
    typealias For = LedgerEntry;
    
    init(_ data: LedgerEntrySnapshot) {
        self.snapshot = data;
    }
    
    @Bindable private var snapshot : LedgerEntrySnapshot;
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let labelMinWidth: CGFloat = 60;
    let labelMaxWidth: CGFloat = 70;
#else
    let labelMinWidth: CGFloat = 80;
    let labelMaxWidth: CGFloat = 85;
#endif
    
    var body: some View {
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
struct LedgerEntryInspect : ElementInspectorView {
    typealias For = LedgerEntry;
    
    init(_ data: LedgerEntry) {
        self.target = data;
    }
    
    let target: LedgerEntry;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let labelMinWidth: CGFloat = 60;
    let labelMaxWidth: CGFloat = 70;
#else
    let labelMinWidth: CGFloat = 80;
    let labelMaxWidth: CGFloat = 85;
#endif
    
    var body: some View {
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
                        NamedPairViewer(pair: cat)
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
                        NamedPairViewer(pair: acc)
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

typealias LedgerEntryIE = ElementIE<LedgerEntry>;

#Preview {
    LedgerEntryIE(LedgerEntry.exampleEntry, isEdit: true).modelContainer(Containers.debugContainer)
}

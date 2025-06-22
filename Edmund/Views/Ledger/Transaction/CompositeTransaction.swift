//
//  CompositeTransaction.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI;
import EdmundCore
import Foundation;

public extension Array {
    func windows(_ count: Int) -> [[Element]] {
        return (0..<self.count).map {
            stride(from: $0, to: count, by: self.count).map { self[$0] }
        }
    }
}

struct CompositeTransaction : TransactionEditorProtocol {
    enum Mode : Int, Identifiable {
        case debit, credit
        
        var id: Self { self }
    }
    struct DataWrapper : Identifiable {
        var data: Decimal = 0.0;
        var id: UUID = UUID();
    }
    struct DataList : Identifiable {
        var data: [DataWrapper];
        var id: UUID = UUID();
    }
    
#if os(macOS)
    let minWidth: CGFloat = 75;
    let maxWidth: CGFloat = 85;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    private var warning = StringWarningManifest();
    @State private var mode: Mode = .debit;
    @State private var working: String = "";
    @Bindable private var snapshot = LedgerEntrySnapshot();
    @Environment(\.modelContext) private var modelContext;
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func computeWorking() -> Decimal? {
        let split = working.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.map { $0.isEmpty ? Decimal() : Decimal(string: $0) };
        
        guard !split.isEmpty else {
            return Decimal()
        }
        
        var result: Decimal = 0;
        for item in split {
            guard let item = item else {
                return nil;
            }
            
            result += item;
        }
        
        return result;
    }
    
    func apply() -> Bool {
        guard snapshot.validate() else {
            warning.warning = .init(message: "Please fix all fields.");
            return false;
        }
        
        let newTrans = LedgerEntry();
        snapshot.apply(newTrans, context: modelContext);
        
        guard let total = computeWorking() else {
            warning.warning = .init(message: "Please ensure that the elements are numbers separated by commas.");
            return false;
        }
        
        if mode == .debit {
            newTrans.debit = total
        }
        else {
            newTrans.credit = total
        }
        
        modelContext.insert(newTrans)
        return true
    }
    
    var body : some View {
        TransactionEditorFrame(.composite, warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Memo:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    
                    TextField("Memo", text: $snapshot.name)
                            .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("Date", selection: $snapshot.date, displayedComponents: .date)
                            .labelsHidden()
                
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Location:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Location", text: $snapshot.location)
                            .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                GridRow {
                    Text("Category:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($snapshot.category)
                }
                GridRow {
                    Text("Account:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($snapshot.account)
                }
                
                Divider()
                
                GridRow {
                    Text("Amount Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $mode) {
                        Text(ledgerStyle.displayCredit).tag(Mode.credit)
                        Text(ledgerStyle.displayDebit).tag(Mode.debit)
                    }.labelsHidden()
                        .pickerStyle(.segmented)
                }
                
                GridRow {
                    Text("Expression:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("", text: $working)
                        .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                }
                
                GridRow {
                    Text("")
                    HStack {
                        Text("Please enter the values, separated by commas (',')")
                            .italic()
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Total:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(self.computeWorking() ?? Decimal.nan, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
            }
        })
    }
}

#Preview {
    CompositeTransaction()
        .modelContainer(Containers.debugContainer)
}

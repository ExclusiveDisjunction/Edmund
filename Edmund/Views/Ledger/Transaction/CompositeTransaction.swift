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
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    private var warning = StringWarningManifest();
    @State private var mode: Mode = .debit;
    @State private var data: [DataWrapper];
    @Bindable private var snapshot = LedgerEntrySnapshot();
    @Environment(\.modelContext) private var modelContext;
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    
    var groups: [[DataWrapper]] {
        data.windows(4);
    }
    
    func apply() -> Bool {
        guard snapshot.validate() else {
            warning.warning = .init(message: "Please fix all fields.");
            return false;
        }
        
        let newTrans = LedgerEntry();
        snapshot.apply(newTrans, context: modelContext);
    }
    
    var body : some View {
        TransactionEditorFrame(.composite, warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Memo:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        TextField("Memo", text: $snapshot.name)
                            .textFieldStyle(.roundedBorder)
                        Spacer()
                    }
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
                    
                    HStack {
                        TextField("Location", text: $snapshot.location)
                            .textFieldStyle(.roundedBorder)
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                GridRow {
                    
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
            }
            
            VStack {
                
            }
        })
    }
}

#Preview {
    CompositeTransaction(vm: CompositeTransactionVM())
}

//
//  BillEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

/// The edit view for Bills. 
public struct BillEdit : View, ElementEditorView {
    public typealias For = Bill;
    
    @Bindable private var snapshot: BillSnapshot;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public init(_ snapshot: BillSnapshot) {
        self.snapshot = snapshot;
    }
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Grid {
            BillBaseEditor(editing: snapshot, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                CurrencyField(snapshot.amount)
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Picker("", selection: $snapshot.kind) {
                        Text(BillsKind.subscription.name).tag(BillsKind.subscription)
                        Text(BillsKind.bill.name).tag(BillsKind.bill)
                    }.labelsHidden()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ElementEditor(Bill(kind: .subscription), adding: false)
        .modelContainer(Containers.debugContainer)
}

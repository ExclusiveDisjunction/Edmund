//
//  BillEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

public struct BillInspect : View, ElementInspectorView {
    public typealias For = Bill;
    
    private var data: Bill;
    public init(_ data: Bill) {
        self.data = data;
    }
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    public let minWidth: CGFloat = 110;
    public let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Grid {
            BillBaseInspect(target: data, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.amount, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.kind.name)
                    Spacer()
                }
            }
        }
    }
}

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
            BillBaseEditor(editing: snapshot.base, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    .foregroundStyle(
                        snapshot.base.errors.contains(.amount) ? .red : .primary
                    )
                    
                HStack {
                    CurrencyField($snapshot.amount, label: "Amount")
                    Spacer()
                }
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    .foregroundStyle(
                        snapshot.base.errors.contains(.amount) ? .red : .primary
                    )
                
                HStack {
                    Picker("Kind", selection: $snapshot.kind) {
                        Text(BillsKind.subscription.name).tag(BillsKind.subscription)
                        Text(BillsKind.bill.name).tag(BillsKind.bill)
                    }.labelsHidden()
                    Spacer()
                }
            }
        }
    }
}

public typealias BillIE = ElementIE<Bill>;

#Preview {
    let bill = Bill.exampleSubscriptions[0];
    ElementIE(bill, mode: .view)
}

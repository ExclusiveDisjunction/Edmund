//
//  BillPayment.swift
//  Edmund
//
//  Created by Hollan on 1/16/25.
//

import SwiftUI
import SwiftData

struct BillPayment : TransactionEditorProtocol {
    init(_ signal: TransactionEditorSignal, kind: BillsKind) {
        self.signal = signal;
        self.kind = kind == .utility ? .bill : kind;
        self.signal.action = apply;
    }
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    @Query private var bills: [Bill];
    
    var signal: TransactionEditorSignal;
    @State private var kind: BillsKind;
    @State private var cache: [Bill] = [];
    @State private var selected: Bill?;
    @State private var date: Date = .now;
    @State private var account: SubAccount?;
    @State private var editing: Bill?;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        cache = bills.filter { $0.kind == kind && !$0.isExpired }.sorted(by: { $0.name < $1.name } );
    }
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        false;
    }
    
    var body: some View {
        Grid {
            GridRow {
                Text("Paying:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                HStack {
                    Picker("Bill", selection: $selected) {
                        Text("Select One", comment: "Select One bill").tag(nil as Bill?)
                        ForEach(cache, id: \.id) { bill in
                            Text(bill.name).tag(bill)
                        }
                    }.labelsHidden()
                    Spacer()
                }
            }
            Divider()
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(selected?.amount ?? Decimal(), format: .currency(code: currencyCode))
                        .padding(.trailing)
                    Button("Edit Bill", action: { editing = selected } ).disabled(selected == nil)
                    
                    Spacer()
                }
            }
            GridRow {
                Text("From:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    NamedPairPicker($account)
                    
                    Spacer()
                }
            }
            GridRow {
                Text("Date:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                    
                    Button("Today", action: { date = .now } )
                    
                    Spacer()
                }
            }
        }.onChange(of: bills, refresh)
            .onChange(of: kind, refresh)
            .onAppear(perform: refresh)
            .sheet(item: $editing) { bill in
                ElementEditor(bill)
                    .destroyOnCancel()
            }
    }
}

#Preview {
    BillPayment(.init(), kind: .subscription)
        .modelContainer(Containers.debugContainer)
        .padding()
}

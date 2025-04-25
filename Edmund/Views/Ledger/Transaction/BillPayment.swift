//
//  BillPayment.swift
//  Edmund
//
//  Created by Hollan on 1/16/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct BillPayment : TransactionEditorProtocol {
    init(kind: BillsKind) {
        self.kind = kind;
        
        _bills = Query(filter: BillPayment.predicate(kind: kind), sort: \Bill.name)
    }
    
    private static func predicate(kind: BillsKind) -> Predicate<Bill> {
        let distantFuture = Date.distantFuture;
        let now = Date.now;
        let kind = kind.rawValue;
        return #Predicate<Bill> { utility in
            return (utility.endDate ?? distantFuture) > now && utility.rawKind == kind
        }
    }
    
    func apply() -> Bool {
        guard let target = selected, let account = account else {
            warning.warning = .init(message: "Please fill in all fields");
            return false;
        }
        
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "internalError");
            return false;
        }
        
        let amount = target.amount;
        let company = target.company;
        let name = target.name;
        
        let trans = LedgerEntry(
            name: name,
            credit: 0,
            debit: amount,
            date: date,
            location: company,
            category: kind == .bill ? categories.bills.bill : categories.bills.subscription,
            account: account
        );
        
        modelContext.insert(trans);
        return true;
    }
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    @Query private var bills: [Bill];
    
    private let kind: BillsKind;
    @State private var selected: Bill? = nil;
    @State private var date: Date = .now;
    @State private var account: SubAccount? = nil;
    @State private var editing: Bill? = nil;
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        TransactionEditorFrame(.billPay(kind), warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Paying:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Picker("Bill", selection: $selected) {
                            Text("Select One", comment: "Select One bill").tag(nil as Bill?)
                            ForEach(bills, id: \.id) { bill in
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
            }.sheet(item: $editing) { bill in
                ElementEditor(bill)
                    .destroyOnCancel()
            }
        })
    }
}

#Preview {
    BillPayment(kind: .subscription)
        .modelContainer(Containers.debugContainer)
        .padding()
}

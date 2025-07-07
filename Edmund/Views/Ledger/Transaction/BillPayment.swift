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
    init(kind: StrictBillsKind)  {
        self.kind = kind;
        
        _bills = Query(filter: BillPayment.predicate(kind: kind), sort: \Bill.name)
    }
    
    @Query private var bills: [Bill];
    
    private let kind: StrictBillsKind;
    @State private var selected: Bill? = nil;
    @State private var date: Date = .now;
    @State private var account: SubAccount? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    private static func predicate(kind: StrictBillsKind) -> Predicate<Bill> {
        let distantFuture = Date.distantFuture;
        let now = Date.now;
        let kind = kind.rawValue;
        return #Predicate<Bill> { bill in
            return (bill.endDate ?? distantFuture) > now && bill._kind == kind
        }
    }

    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        guard let target = selected, let account = account else {
            return .empty
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
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.billPay(kind), apply: apply) {
            Grid {
                GridRow {
                    Text("Paying:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("Bill", selection: $selected) {
                        Text("Select One", comment: "Select One bill").tag(nil as Bill?)
                        ForEach(bills, id: \.id) { bill in
                            Text(bill.name).tag(bill)
                        }
                    }.labelsHidden()
                }
                Divider()
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(selected?.amount ?? Decimal(), format: .currency(code: currencyCode))
                            .padding(.trailing)
                        
                        Spacer()
                    }
                }
                GridRow {
                    Text("From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($account)
                        .namedPairPickerStyle(horizontalSizeClass == .compact ? .vertical : .horizontal)
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
            }
        }
    }
}

#Preview {
    DebugContainerView {
        BillPayment(kind: .subscription)
    }
}

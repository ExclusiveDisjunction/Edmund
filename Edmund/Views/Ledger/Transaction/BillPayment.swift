//
//  BillPayment.swift
//  Edmund
//
//  Created by Hollan on 1/16/25.
//

import SwiftUI
import SwiftData
import EdmundCore

@available(*, deprecated, message: "Use BillPayment or UtilityPayment instead")
struct UnifiedBillPayment<T> : TransactionEditorProtocol where T: BillBase & PersistentModel & AnyObject {
    
    private let kind: BillsKind;
    private let predicate: Predicate<T>;
    @State private var selected: T? = nil;
    @State private var date: Date = .now;
    @State private var account: Account? = nil;
    @Bindable private var amount: CurrencyValue = .init();
    
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
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let amount = amount.rawValue;
        guard amount >= 0 else {
            return .negativeAmount
        }
        guard let target = selected, let account = account else {
            return .empty
        }
        
        let transaction = LedgerEntry(
            name: target.name,
            credit: 0,
            debit: amount,
            date: date,
            location: target.location ?? "Bank",
            category: categories.bills,
            account: account
        );
        
        modelContext.insert(transaction);
        target.addPoint(amount: amount)
        
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.billPay(kind), apply: apply) {
            Grid {
                GridRow {
                    Text("Target:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($selected, withPredicate: predicate, sortOn: \.name)
                }
                
                Divider()
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                GridRow {
                    Text("From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($account)
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
            }.onChange(of: selected) { _, newValue in
                guard let value = newValue else {
                    return;
                }
                
                self.amount.rawValue = value.amount;
                self.amount.format(context: currencyCode)
            }
        }
    }
}

struct BillPaymentBase : View {
    let minWidth: CGFloat;
    let maxWidth: CGFloat;
    
    let amount: CurrencyValue;
    @Binding var account: Account?;
    @Binding var date: Date;
    
    var body : some View {
        Divider()
        
        GridRow {
            Text("Amount:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            CurrencyField(amount)
        }
        
        GridRow {
            Text("From:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            ElementPicker($account)
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

struct BillPayment : TransactionEditorProtocol {
    init(kind: StrictBillsKind) {
        self.kind = (kind == .subscription ? .subscription : .bill);
        
        let distantFuture = Date.distantFuture;
        let now = Date.now;
        let kind = kind.rawValue;
        
        self.predicate = #Predicate<Bill> { bill in
            return (bill.endDate ?? distantFuture) > now && bill._kind == kind
        }
    }
    
    private let kind: StrictBillsKind;
    private let predicate: Predicate<Bill>;
    @State private var selected: Bill? = nil;
    @State private var date: Date = .now;
    @State private var account: Account? = nil;
    @Bindable private var amount: CurrencyValue = .init();
    
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
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let amount = amount.rawValue;
        guard amount >= 0 else {
            return .negativeAmount
        }
        guard let target = selected, let account = account else {
            return .empty
        }
        
        let transaction = LedgerEntry(
            name: target.name,
            credit: 0,
            debit: amount,
            date: date,
            location: target.location ?? "Bank",
            category: categories.bills,
            account: account
        );
        
        modelContext.insert(transaction);
        target.addPoint(amount: amount)
        
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.billPay(kind == .bill ? .bill : .subscription), apply: apply) {
            Grid {
                GridRow {
                    Text(kind == .bill ? "Bill:" : "Subscription:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($selected, withPredicate: predicate, sortOn: \.name)
                }
                
                BillPaymentBase(minWidth: minWidth, maxWidth: maxWidth, amount: amount, account: $account, date: $date)
            }.onChange(of: selected) { _, newValue in
                guard let value = newValue else {
                    return;
                }
                
                self.amount.rawValue = value.amount;
                self.amount.format(context: currencyCode)
            }
        }
    }
}
struct UtilityPayment : TransactionEditorProtocol {
    init() {
        let distantFuture = Date.distantFuture;
        let now = Date.now;
        
        self.predicate = #Predicate<Utility> { utility in
            (utility.endDate ?? distantFuture) > now
        };
    }
    
    private let predicate: Predicate<Utility>;
    @State private var selected: Utility? = nil;
    @State private var date: Date = .now;
    @State private var account: Account? = nil;
    @Bindable private var amount: CurrencyValue = .init();
    
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
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let amount = amount.rawValue;
        guard amount >= 0 else {
            return .negativeAmount
        }
        guard let target = selected, let account = account else {
            return .empty
        }
        
        let transaction = LedgerEntry(
            name: target.name,
            credit: 0,
            debit: amount,
            date: date,
            location: target.location ?? "Bank",
            category: categories.bills,
            account: account
        );
        
        modelContext.insert(transaction);
        target.addPoint(amount: amount)
        
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.billPay(.utility), apply: apply) {
            Grid {
                GridRow {
                    Text("Utility:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($selected, withPredicate: predicate, sortOn: \.name)
                }
                
                BillPaymentBase(minWidth: minWidth, maxWidth: maxWidth, amount: amount, account: $account, date: $date)
            }.onChange(of: selected) { _, newValue in
                guard let value = newValue else {
                    return;
                }
                
                self.amount.rawValue = value.amount;
                self.amount.format(context: currencyCode)
            }
        }
    }
}

#Preview {
    DebugContainerView {
        BillPayment(kind: .subscription)
    }
}

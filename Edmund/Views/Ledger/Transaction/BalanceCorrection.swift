//
//  Audit.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI
import EdmundCore

struct BalanceCorrection: TransactionEditorProtocol {
    private enum Mode : Identifiable, CaseIterable, Displayable {
        case setAmount, byBalance
        
        var id: Self { self }
        
        var display: LocalizedStringKey {
            switch self {
                case .setAmount: "Fixed Amount"
                case .byBalance: "Balance Goal"
            }
        }
    }
    
    @State private var account: SubAccount? = nil;
    @State private var mode: Self.Mode = .byBalance;
    @State private var currentBalance: Decimal? = nil;
    @State private var date: Date = .now;
    @Bindable private var amount: CurrencyValue = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 100;
    private let maxWidth: CGFloat = 110;
#endif
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let amount = amount.rawValue;
        guard let account = account else {
            return .empty
        }
        
        let transaction = LedgerEntry(
            name: "Audit",
            credit: amount >= 0 ? amount : 0,
            debit: amount < 0 ? -amount : 0,
            date: date,
            location: "Bank",
            category: categories.accountControl.audit,
            account: account
        );
        
        modelContext.insert(transaction);
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.balanceCorrection, apply: apply) {
            Grid {
                GridRow {
                    Text("Account:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($account)
                        .namedPairPickerStyle(horizontalSizeClass == .compact ? .vertical : .horizontal)
                        .onChange(of: account) { _, newAcc in
                            Task {
                                await MainActor.run {
                                    withAnimation {
                                        currentBalance = newAcc?.transactions?.reduce(0, { $0 + $1.credit - $1.debit})
                                    }
                                }
                            }
                        }
                }
                GridRow {
                    Text("Balance:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        if let balance = currentBalance, account != nil {
                            Text(balance, format: .currency(code: currencyCode))
                        }
                        else if account != nil {
                            ProgressView().progressViewStyle(.linear)
                        }
                        else {
                            Text("(No balance)")
                                .italic()
                        }
                        Spacer()
                    }
                }
                
                GridRow {
                    Text(mode == .byBalance ? "Amount:" : "Goal:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                if mode == .byBalance {
                    GridRow {
                        Text("New Balance:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        HStack {
                            if let balance = currentBalance, account != nil {
                                Text(balance + amount.rawValue, format: .currency(code: currencyCode))
                            }
                            else if account != nil {
                                ProgressView().progressViewStyle(.linear)
                            }
                            else {
                                Text("(No balance)")
                                    .italic()
                            }
                            Spacer()
                        }
                    }
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        
                        Button("Today") {
                            date = .now
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    DebugContainerView {
        BalanceCorrection()
    }
}

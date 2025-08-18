//
//  PaydayEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/18/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct PaydayTransaction : TransactionEditorProtocol {
    @Query private var salaried: [SalariedJob];
    @Query private var hourly: [HourlyJob];
    
    @State private var jobID: TraditionalJobID? = nil;
    @State private var job: TraditionalJobWrapper? = nil;
    @State private var deposit: SubAccount? = nil;
    @State private var amount: CurrencyValue = .init();
    @State private var date: Date = .now;
    
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
        guard let cats = categoriesContext else {
            return .internalError
        }
        
        guard let job = job, let deposit = deposit else {
            return .empty
        }
        guard amount.rawValue >= 0 else {
            return .negativeAmount
        }
        
        let transaction = LedgerEntry(
            name: "Payday",
            credit: amount.rawValue,
            debit: 0,
            date: date,
            location: job.data.company,
            category: cats.accountControl.pay,
            account: deposit
        );
        
        modelContext.insert(transaction)
        
        return nil;
    }
    
    @ViewBuilder
    private func pickerContent() -> some View {
        Text("(No job)")
            .italic()
            .tag(nil as TraditionalJobID?)
        if !salaried.isEmpty {
            Section("Salaried") {
                ForEach(salaried) { job in
                    Text(job.position).tag(job.id)
                }
            }
        }
        
        if !hourly.isEmpty {
            Section("Hourly") {
                ForEach(hourly) { job in
                    Text(job.position).tag(job.id)
                }
            }
        }
    }
    
    var body: some View {
        TransactionEditorFrame(.payday, apply: apply) {
            Grid {
                GridRow {
                    Text("Job:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $jobID, content: pickerContent)
                        .labelsHidden()
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                GridRow {
                    Text("Deposit To:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($deposit)
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        Button("Today") {
                            date = .now
                        }
                        Spacer()
                    }
                }
            }
        }.onChange(of: jobID) { _, newID in
            guard let id = newID else {
                job = nil;
                return;
            }
            
            if let target = salaried.first(where: { $0.id == id } ) {
                job = .init(target)
            }
            else if let target = hourly.first(where: { $0.id == id } ) {
                job = .init(target)
            }
            else {
                job = nil;
            }
        }.onChange(of: job) { _, newJob in
            if let job = newJob {
                amount.rawValue = job.data.estimatedProfit
            }
            else {
                amount.rawValue = 0;
            }
            
            amount.format(context: currencyCode)
        }
    }
}

#Preview {
    DebugContainerView {
        PaydayTransaction()
    }
}

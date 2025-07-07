//
//  SpendingGraph.swift
//  Edmund
//
//  Created by Hollan on 5/8/25.
//

import SwiftUI
import SwiftData
import Charts
import EdmundCore

struct SpendingComputation: Identifiable, Sendable {
    init(_ monthYear: MonthYear, _ data: [LedgerEntry]) {
        self.monthYear = monthYear
        let computed = data.reduce((0.0, 0.0), { acc, trans in
            (acc.0 + trans.credit, acc.1 + trans.debit)
        })
        
        self.credit = computed.0
        self.debit = computed.1
        self.id = UUID()
    }
    
    let id: UUID;
    let monthYear: MonthYear;
    let credit: Decimal;
    let debit: Decimal;
    var balance: Decimal {
        self.credit - self.debit
    }
    
    var label: String {
        self.monthYear.asDate.formatted(date: .abbreviated, time: .omitted)
    }
}

enum SpendingGraphMode: Int, Identifiable, CaseIterable, Sendable {
    case net
    case individual
    
    var name: LocalizedStringKey {
        switch self {
            case .net: "Net Spending"
            case .individual: "Individual Spending"
        }
    }
    var id: Self { self }
}

struct SpendingGraph : View {
    @Query private var entries: [LedgerEntry];
    @State private var resolved: [SpendingComputation]? = nil;
    
    @AppStorage("spendingGraphShowingLast") private var showingLast: Int = 10;
    @AppStorage("spendingGraphMode") private var spendingGraphMode: SpendingGraphMode = .net;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func load() -> [SpendingComputation] {
        let split = TransactionResolver.splitByMonth(entries);
        return Array(split.map(SpendingComputation.init).sorted(using: KeyPathComparator(\SpendingComputation.monthYear, order: .forward)).prefix(showingLast))
    }
    
    var body: some View {
        Picker("", selection: $spendingGraphMode) {
            ForEach(SpendingGraphMode.allCases, id: \.id) { mode in
                Text(mode.name).tag(mode)
            }
        }.pickerStyle(.segmented)
            .labelsHidden()
        
        LoadableView($resolved, process: load, onLoad: { resolved in
            Chart(resolved) { pair in
                if spendingGraphMode == .net {
                    BarMark(
                        x: .value(Text(verbatim: pair.label), pair.monthYear.asDate, unit: .month),
                        y: .value(Text(pair.balance, format: .currency(code: currencyCode)), pair.balance)
                    )
                    .foregroundStyle(pair.balance < 0 ? .red : .green)
                }
                else {
                    BarMark(
                        x: .value(Text(verbatim: pair.label), pair.monthYear.asDate, unit: .month),
                        y: .value(Text(pair.credit, format: .currency(code: currencyCode)), pair.credit)
                    )
                    .foregroundStyle(.green)
                    
                    BarMark(
                        x: .value(Text(verbatim: pair.label), pair.monthYear.asDate, unit: .month),
                        y: .value(Text(-pair.debit, format: .currency(code: currencyCode)), -pair.debit)
                    )
                    .foregroundStyle(.red)
                }
            }.chartLegend(.visible).chartXAxisLabel("Month & Year").chartYAxisLabel("Amount")
        })
    }
}

#Preview {
    DebugContainerView {
        SpendingGraph()
            .padding()
            .frame(width: 500)
    }
}

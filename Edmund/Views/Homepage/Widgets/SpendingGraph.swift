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

struct SpendingComputation: Identifiable {
    init(_ monthYear: MonthYear, _ data: [LedgerEntry]) {
        self.monthYear = monthYear
        let computed = data.reduce((0.0, 0.0), { acc, trans in
            (acc.0 + trans.credit, acc.1 + trans.debit)
        })
        
        self.balance = computed.0 - computed.1
        self.id = UUID()
    }
    
    var id: UUID;
    var monthYear: MonthYear;
    var balance: Decimal;
    
    var label: String {
        self.monthYear.asDate.formatted(date: .abbreviated, time: .omitted)
    }
}

struct SpendingGraph : View {
    @Query private var entries: [LedgerEntry];
    @State private var resolved: [SpendingComputation]? = nil;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func load() -> [SpendingComputation] {
        let split = TransactionResolver.splitByMonth(entries);
        return split.map(SpendingComputation.init)
    }
    
    var body: some View {
        LoadableView($resolved, process: load, onLoad: { resolved in
            Chart(resolved) { pair in
                BarMark(
                    x: .value(Text(verbatim: pair.label), pair.monthYear.asDate, unit: .month),
                    y: .value(Text(pair.balance, format: .currency(code: currencyCode)), pair.balance)
                )
                .foregroundStyle(pair.balance < 0 ? .red : .green)
            }.chartLegend(.visible)
        })
    }
}

#Preview {
    SpendingGraph()
        .padding()
        .frame(width: 500)
        .modelContainer(Containers.debugContainer)
}

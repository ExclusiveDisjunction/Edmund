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
    init(_ monthYear: MonthYear, _ data: [LedgerEntry], id: UUID = UUID()) {
        self.monthYear = monthYear
        self.id = id
        self.balance = data.reduce(BalanceInformation(), { acc, trans in
            acc + BalanceInformation(credit: trans.credit, debit: trans.debit)
        })
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.locale = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        
        if let date = Calendar.current.date(from: DateComponents(year: monthYear.year, month: monthYear.month)) {
            label = dateFormatter.string(from: date)
        }
        else {
            label = NSLocalizedString("internalError", comment: "")
        }
    }
    
    let id: UUID;
    let monthYear: MonthYear;
    let label: String;
    let balance: BalanceInformation;
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
        let split = TransactionResolver(entries).splitByMonth()
        return Array(
            split
                .map {
                    SpendingComputation($0.key, $0.value)
                }
                .sorted(using: KeyPathComparator(\.monthYear, order: .forward))
                .prefix(showingLast)
        )
    }
    
    var body: some View {
        Picker("", selection: $spendingGraphMode) {
            ForEach(SpendingGraphMode.allCases, id: \.id) { mode in
                Text(mode.name).tag(mode)
            }
        }.pickerStyle(.segmented)
            .labelsHidden()
        
        LoadableView($resolved, process: load) { resolved in
            if resolved.isEmpty {
                Text("There is not enough transactions to show spending.")
                    .italic()
            }
            else {
                Chart(resolved) { pair in
                    if spendingGraphMode == .net {
                        BarMark(
                            x: .value(Text(verbatim: pair.label), pair.monthYear.asDate ?? Date.distantFuture, unit: .month),
                            y: .value(Text(pair.balance.balance, format: .currency(code: currencyCode)), pair.balance.balance)
                        )
                        .foregroundStyle(pair.balance.balance < 0 ? .red : .green)
                    }
                    else {
                        BarMark(
                            x: .value(Text(verbatim: pair.label), pair.monthYear.asDate ?? Date.distantFuture, unit: .month),
                            y: .value(Text(pair.balance.credit, format: .currency(code: currencyCode)), pair.balance.credit)
                        )
                        .foregroundStyle(.green)
                        
                        BarMark(
                            x: .value(Text(verbatim: pair.label), pair.monthYear.asDate ?? Date.distantFuture, unit: .month),
                            y: .value(Text(-pair.balance.debit, format: .currency(code: currencyCode)), -pair.balance.debit)
                        )
                        .foregroundStyle(.red)
                    }
                }.chartLegend(.visible).chartXAxisLabel("Month & Year").chartYAxisLabel("Amount")
            }
        }
    }
}

#Preview {
    DebugContainerView {
        SpendingGraph()
            .padding()
            .frame(width: 500)
    }
}

//
//  SpendingGraph.swift
//  Edmund
//
//  Created by Hollan on 5/8/25.
//

import SwiftUI
import Charts

struct SpendingComputation: Identifiable, Sendable {
    init(_ monthYear: MonthYear, balance: BalanceInformation, calendar: Calendar, id: UUID = UUID()) {
        self.monthYear = monthYear
        self.id = id
        self.balance = balance;
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.locale = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        
        if let date = calendar.date(from: DateComponents(year: monthYear.year, month: monthYear.month)) {
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
    @State private var resolved: [SpendingComputation]? = nil;
    
    @AppStorage("spendingGraphShowingLast") private var showingLast: Int = 10;
    @AppStorage("spendingGraphMode") private var spendingGraphMode: SpendingGraphMode = .net;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @Environment(\.calendar) private var calendar;
    
    private func load() async throws -> [SpendingComputation] {
        let split = try await BalanceResolver.splitTransactionsByMonth(using: DataStack.shared.currentContainer, calendar: calendar)
        
        return await Task(priority: .medium) {
            return Array(
                split
                    .map {
                        SpendingComputation($0.key, balance: $0.value, calendar: calendar)
                    }
                    .sorted(using: KeyPathComparator(\.monthYear, order: .forward))
                    .prefix(showingLast)
            )
        }.value
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
                            x: .value(Text(verbatim: pair.label), pair.monthYear.start(calendar: calendar) ?? Date.distantFuture, unit: .month),
                            y: .value(Text(pair.balance.balance, format: .currency(code: currencyCode)), pair.balance.balance)
                        )
                        .foregroundStyle(pair.balance.balance < 0 ? .red : .green)
                    }
                    else {
                        BarMark(
                            x: .value(Text(verbatim: pair.label), pair.monthYear.start(calendar: calendar) ?? Date.distantFuture, unit: .month),
                            y: .value(Text(pair.balance.credit, format: .currency(code: currencyCode)), pair.balance.credit)
                        )
                        .foregroundStyle(.green)
                        
                        BarMark(
                            x: .value(Text(verbatim: pair.label), pair.monthYear.start(calendar: calendar) ?? Date.distantFuture, unit: .month),
                            y: .value(Text(-pair.balance.debit, format: .currency(code: currencyCode)), -pair.balance.debit)
                        )
                        .foregroundStyle(.red)
                    }
                }.chartLegend(.visible).chartXAxisLabel("Month & Year").chartYAxisLabel("Amount")
            }
        }
    }
}

#Preview(traits: .sampleData) {
    SpendingGraph()
        .padding()
        .frame(width: 500)
}

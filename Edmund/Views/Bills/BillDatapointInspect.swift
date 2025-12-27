//
//  UtilityEntryInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI


public struct BillDatapointInspect : View {
    public let over: Bill;
    
    @State private var cache: [ResolvedBillHistory]?;
    @State private var selected = Set<UUID>();
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.calendar) private var calendar;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() -> [ResolvedBillHistory] {
        var dates = TimePeriodWalker(start: over.startDate, end: over.endDate, period: over.period, calendar: calendar)
        return over.history.map {
            ResolvedBillHistory(from: $0, date: dates.step())
        }
    }
    
    @ViewBuilder
    private func amountDisplay(_ amount: Decimal?) -> some View {
        if let amount = amount {
            Text(amount, format: .currency(code: currencyCode))
        }
        else {
            Text("Skipped")
                .italic()
        }
    }
    @ViewBuilder
    private func dateDisplay(_ date: Date?) -> some View {
        if let date = date {
            Text(date.formatted(date: .abbreviated, time: .omitted))
        }
        else {
            Text("(No date)")
                .italic()
        }
    }
    
    public var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            
            LoadableView($cache, process: refresh) { cache in
                if cache.isEmpty {
                    Text("There is no history to view.")
                        .italic()
                }
                else {
                    Table(cache, selection: $selected) {
                        TableColumn("Amount") { child in
                            if horizontalSizeClass == .compact {
                                HStack {
                                    amountDisplay(child.amount)
                                    
                                    Spacer()
                                    
                                    dateDisplay(child.date)
                                }
                            }
                            else {
                                amountDisplay(child.amount)
                            }
                        }
                        TableColumn("Date") { child in
                            dateDisplay(child.date)
                        }
                    }.onChange(of: over.history) { _, _ in
                        self.cache = refresh()
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }
        .padding()
#if os(macOS)
        .frame(minHeight: 350)
#endif
    }
}

#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<Bill>(sortDescriptors: []) var bills: FetchedResults<Bill>;
    
    BillDatapointInspect(over: bills[0])
        .padding()
}

//
//  UtilityEntryInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData
import EdmundCore

/// The inspection view for Utility Entries.  This provides the layout for viewing all datapoints.
public struct BillHistoryInspect<T> : View where T: BillBase {
    public var over: T;
    
    @State private var cache: [ResolvedBillHistory] = [];
    @State private var selected = Set<UUID>();
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.calendar) private var calendar;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        var dates = TimePeriodWalker(start: over.startDate, end: over.endDate, period: over.period, calendar: calendar)
        self.cache = over.history.map {
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
                }.onAppear(perform: refresh)
                    .onChange(of: over.history) { _, _ in
                        refresh()
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

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @Query var utilities: [Utility];
    BillHistoryInspect(over: utilities.first!)
}

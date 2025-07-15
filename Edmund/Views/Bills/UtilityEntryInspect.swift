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
public struct UtilityEntriesInspect : View {
    public var over: Utility;
    
    @State private var cache: [UtilityEntryRow<Decimal>] = [];
    @State private var selected = Set<UUID>();
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.calendar) private var calendar;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        var dates = TimePeriodWalker(start: over.startDate, end: over.endDate, period: over.period, calendar: calendar)
        self.cache = over.points.map { amount in
            UtilityEntryRow(amount: amount, date: dates.step())
        }
    }
    
    public var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            
            Table(cache, selection: $selected) {
                TableColumn("Amount") { child in
                    if horizontalSizeClass == .compact {
                        HStack {
                            Text(child.amount, format: .currency(code: currencyCode))
                            
                            Spacer()
                            
                            Text("On", comment: "[Amount] on [Date]")
                            if let date = child.date {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                            }
                            else {
                                Text("(No date)")
                                    .italic()
                            }
                            
                        }
                    }
                    else {
                        Text(child.amount, format: .currency(code: currencyCode))
                    }
                }
                TableColumn("Date") { child in
                    if let date = child.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                    }
                    else {
                        Text("(No date)")
                            .italic()
                    }
                }
            }.onAppear(perform: refresh)
                .onChange(of: over.points) { _, _ in
                    refresh()
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

#Preview {
    UtilityEntriesInspect(over: Utility.exampleUtility[0])
        .padding()
}

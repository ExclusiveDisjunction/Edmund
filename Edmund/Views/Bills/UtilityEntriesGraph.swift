//
//  Untitled.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData
import Charts
import EdmundCore

/// A line graph that shows the spending over time, separated by dates. 
public struct UtilityEntriesGraph : View {
    public var source: Utility;
    
    @Environment(\.calendar) private var calendar;
    @Environment(\.dismiss) private var dismiss;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private var children: [UtilityEntryRow<Decimal>] {
        var walker = TimePeriodWalker(start: source.startDate, end: source.endDate, period: source.period, calendar: calendar);
        return source.points.map { UtilityEntryRow(amount: $0, date: walker.step()) }
    }
    
    public var body: some View {
        VStack {
            Text("Price Over Time").font(.title2)
            
            Chart {
                ForEach(children, id: \.id) { point in
                    LineMark(
                        x: .value("Date", point.date ?? .distantFuture),
                        y: .value("Amount", point.amount),
                        series: .value("Name", source.name)
                    )
                }
            }.frame(minHeight: 250)
                .chartLegend(.visible)
                .chartXAxisLabel("Date")
                .chartYAxisLabel("Amount")
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } )
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

#Preview {
    UtilityEntriesGraph(source: Utility.exampleUtility[0])
}

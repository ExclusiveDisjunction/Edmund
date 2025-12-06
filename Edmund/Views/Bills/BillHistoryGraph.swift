//
//  Untitled.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData
import Charts

/// A line graph that shows the spending over time, separated by dates.
public struct UtilityEntriesGraph : View {
    public var source: Bill;
    
    @Environment(\.calendar) private var calendar;
    @Environment(\.dismiss) private var dismiss;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @State private var hashed: Int = 0;
    @State private var cache: [ResolvedBillHistory]? = nil;
    
    private func refresh() {
        if hashed != source.hashValue || cache == nil {
            var walker = TimePeriodWalker(start: source.startDate, end: source.endDate, period: source.period, calendar: calendar);
            let result = source.history.compactMap {
                if $0.amount != nil, let date = walker.step() {
                    ResolvedBillHistory(from: $0, date: date)
                }
                else {
                    nil
                }
            }
            
            self.cache = result;
            hashed = source.hashValue;
        }
    }
    
    public var body: some View {
        VStack {
            HStack {
                Text("Price Over Time").font(.title2)
                Spacer()
            }
            
            if let children = cache {
                if children.count <= 1 {
                    Text("There is not enough data in the history to graph the price over time.")
                        .italic()
                }
                else {
                    
                    Chart {
                        ForEach(children, id: \.id) { point in
                            LineMark(
                                x: .value("Date", point.date!),
                                y: .value("Amount", point.amount!),
                                series: .value("Name", source.name)
                            )
                        }
                    }.frame(minHeight: 250)
                        .chartLegend(.visible)
                        .chartXAxisLabel("Date")
                        .chartYAxisLabel("Amount")
                }
            }
            else {
                ProgressView()
            }
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } )
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
            .onAppear {
                refresh()
            }
    }
}


#Preview {
    UtilityEntriesGraph(source: Bill.exampleBills[0])
}

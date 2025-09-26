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
public struct UtilityEntriesGraph<T> : View where T: BillBase & Hashable {
    public var source: T;
    
    @Environment(\.calendar) private var calendar;
    @Environment(\.dismiss) private var dismiss;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @State private var hashed: Int = 0;
    @State private var cache: [ResolvedBillHistory]? = nil;
    
    private var children: [ResolvedBillHistory] {
        guard let cache = cache, hashed == source.hashValue else {
            var walker = TimePeriodWalker(start: source.startDate, end: source.endDate, period: source.period, calendar: calendar);
            let result = source.history.compactMap {
                if $0.amount != nil, let date = walker.step() {
                    ResolvedBillHistory(from: $0, date: date)
                }
                else {
                    nil
                }
            }
            
            cache = result;
            hashed = source.hashValue;
            return result;
        }
        
        return cache;
    }
    
    public var body: some View {
        VStack {
            HStack {
                Text("Price Over Time").font(.title2)
                Spacer()
            }
            
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

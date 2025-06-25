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
    public var source: Utility;
    
    private var children: [UtilityEntry] {
        source.children?.sorted(by: { $0.date < $1.date } ) ?? .init()
    }
    
    public var body: some View {
        VStack {
            Text("Price Over Time").font(.title2)
            
            Chart {
                ForEach(children, id: \.id) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount),
                        series: .value("Name", source.name)
                    )
                }
            }.frame(minHeight: 250)
                .chartLegend(.visible)
                .chartXAxisLabel("Date")
                .chartYAxisLabel("Amount")
        }
    }
}

#Preview {
    UtilityEntriesGraph(source: Utility.exampleUtility[0])
}

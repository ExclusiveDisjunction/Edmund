//
//  Widget_macOS.swift
//  Widget-macOS
//
//  Created by Hollan on 4/22/25.
//

import WidgetKit
import SwiftUI
import EdmundCore

struct UpcomingBillsView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family;
    
    private let currencyCode: String = (Locale.current.currency?.identifier ?? "USD");
    
    private var data: [UpcomingBill]? {
        if let data = entry.data {
            Array( data.sorted(by: { $0.dueDate < $1.dueDate } ).prefix(maxVisibleCount) )
        }
        else {
            nil
        }
    }
    private var maxVisibleCount: Int {
        switch family {
            case .systemSmall: 4
            case .systemMedium: 5
            case .systemLarge: 10
            case .systemExtraLarge: 15
            default: 4
        }
    }
    

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Upcoming Bills").font(.title2)
                Spacer()
            }
            
            if let data = data {
                Grid {
                    GridRow {
                        HStack {
                            Text("Name").bold()
                            Spacer()
                        }
                        Spacer()
                        
                        Text("Amount").bold()
                        
                        HStack {
                            Spacer()
                            Text("Due Date").bold()
                        }
                    }
                    Divider()
                    ForEach(data, id: \.id) { item in
                        GridRow {
                            HStack {
                                Text(item.name).lineLimit(1)
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                Spacer()
                                Text(item.amount, format: .currency(code: currencyCode))
                            }
                            
                            HStack {
                                Spacer()
                                Text(item.dueDate.formatted(date: .numeric, time: .omitted))
                            }
                        }
                    }
                }
            }
            else {
                Text("No information could be loaded").italic()
            }
            
            Spacer()
        }.padding()
    }
}

struct UpcomingBills: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "com.exdisj.edmund.widget.macOS", intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            UpcomingBillsView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    UpcomingBills()
} timeline: {
    UpcomingBillsEntry(date: .now, data: [])
}

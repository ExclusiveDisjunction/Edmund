//
//  EdmundWidgets.swift
//  EdmundWidgets
//
//  Created by Hollan Sellars on 7/2/25.
//

import WidgetKit
import SwiftUI
import EdmundWidgetCore

struct UpcomingBillsProvider: TimelineProvider {
    typealias Entry = UpcomingBillsBundle
    func placeholder(in context: Context) -> UpcomingBillsBundle {
        .init(
            date: .now,
            bills: [
                .init(name: "Apple Music", amount: 9.99, dueDate: Date.fromParts(2025, 7, 2)!),
                .init(name: "iCloud", amount: 2.99, dueDate: Date.fromParts(2025, 7, 5)!),
                .init(name: "Electric", amount: 33.45, dueDate: Date.fromParts(2025, 7, 10)!),
                .init(name: "Amazon Prime", amount: 14.99, dueDate: Date.fromParts(2025, 7, 15)!),
                .init(name: "Water", amount: 40.00, dueDate: Date.fromParts(2025, 7, 22)!),
                .init(name: "YouTube Premium", amount: 20.00, dueDate: Date.fromParts(2026, 7, 29)!)
            ]
        )
    }
    private static func getAllSnapshots() async -> [UpcomingBillsBundle]? {
        guard let provider = WidgetDataProvider() else {
            return nil
        }
        
        return try? await UpcomingBillsWidgetManager.extractFromProvider(provider: provider)
    }
    func getSnapshot(in context: Context, completion: @escaping @Sendable (EdmundWidgetCore.UpcomingBillsBundle) -> Void) {
        Task {
            guard let data = await Self.getAllSnapshots(), let first = data.first else {
                return
            }
            
            completion(first)
        }
    }
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<EdmundWidgetCore.UpcomingBillsBundle>) -> Void) {
        Task {
            let updateWhen: Date;
            if let date = Calendar.current.date(byAdding: .day, value: 10, to: .now) {
                updateWhen = date
            }
            else {
                updateWhen = .distantFuture
            }
            guard let data = await Self.getAllSnapshots() else {
                return
            }
            
            completion(.init(entries: data, policy: .after(updateWhen)))
        }
    }
}

struct SquaresBackground : ShapeStyle {
    
}

struct EdmundWidgetsEntryView : View {
    var entry: UpcomingBillsProvider.Entry
    let currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.widgetFamily) private var family;
    @Environment(\.showsWidgetContainerBackground) private var showBackground;
    
    var display: [UpcomingBill] {
        switch family {
            case .systemSmall: Array(entry.bills.prefix(2))
            case .systemMedium: Array(entry.bills.prefix(4))
            case .systemLarge: Array(entry.bills.prefix(10))
            case .systemExtraLarge: Array(entry.bills.prefix(20))
            default: []
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(family == .systemSmall ? "Bills" : "Upcoming Bills")
                    .padding(.top, 2)
                Spacer()
            }
                .font(.headline)
            Divider()
            
            if family == .systemSmall {
                ForEach(display, id: \.id) { bill in
                    HStack {
                        Text(bill.name)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text(bill.dueDate.formatted(date: .numeric, time: .omitted))
                            .italic()
                    }
                }
            }
            else {
                Grid {
                    GridRow {
                        Text("Name")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Amount")
                            .bold()
                        
                        Text("Date")
                            .bold()
                    }
                    
                    ForEach(display, id: \.id) { bill in
                        GridRow {
                            Text(bill.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(bill.amount, format: .currency(code: currencyCode))
                            
                            Text(bill.dueDate.formatted(date: .numeric, time: .omitted))
                        }
                    }
                }
            }
            
            Spacer()
        }.containerBackground(SquaresBackground(), for: .widget)
            .padding(3)
    }
}

struct UpcomingBillsWidget: Widget {
    let kind: String = "EdmundWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingBillsProvider()) { entry in
            EdmundWidgetsEntryView(entry: entry)
        }.containerBackgroundRemovable()
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
            .description("Displays the current upcoming bills, including their name, amount, and due date.")
    }
}

#Preview(as: .systemMedium) {
    UpcomingBillsWidget()
} timeline: {
    UpcomingBillsBundle.example
}

//
//  Provider.swift
//  Edmund
//
//  Created by Hollan on 4/22/25.
//

import WidgetKit
import SwiftUI;
import Foundation
import SwiftData;
import EdmundCore;

func exampleUpcoming() -> [UpcomingBill] {
    return [
        .init(name: "Apple Music",   amount: 10.99,  dueDate: Calendar.current.date(byAdding: .day,   value: 3,  to: Date.now)!),
        .init(name: "iCloud",        amount: 2.99,   dueDate: Calendar.current.date(byAdding: .day,   value: 4,  to: Date.now)!),
        .init(name: "Water",         amount: 70.71,  dueDate: Calendar.current.date(byAdding: .day,   value: 7,  to: Date.now)!),
        .init(name: "Electric",      amount: 160.40, dueDate: Calendar.current.date(byAdding: .day,   value: 12, to: Date.now)!),
        .init(name: "Car Insurance", amount: 10.99,  dueDate: Calendar.current.date(byAdding: .month, value: 1,  to: Date.now)!),
    ]
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UpcomingBillsEntry {
        UpcomingBillsEntry(date: Date.now, data: exampleUpcoming())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> UpcomingBillsEntry {
        UpcomingBillsEntry(date: Date.now, data: exampleUpcoming())
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<UpcomingBillsEntry> {
        print("Widget: Fetching URL");
        let fileURL = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.exdisj.Edmund.BillTracker")?
            .appendingPathComponent("upcomingBills.json");
        
        guard let fileURL = fileURL else {
            fatalError("Unable to get the upcoming bills path.")
        }
        
        print("Widget: Fetching data from URL");
        guard let data = try? Data(contentsOf: fileURL),
              let bills = try? JSONDecoder().decode([UpcomingBillsSnapshot].self, from: data) else {
            print("Unable to get info from the shared container.");
            
            let entry = UpcomingBillsEntry(date: Date.now, data: nil);
            
            return Timeline(entries: [entry], policy: .atEnd)
        }
        
        let entries = bills.map {
            UpcomingBillsEntry(
                date: $0.date,
                data: $0.bills.sorted(by: {
                    $0.dueDate < $1.dueDate
                })
            )
        }.sorted(by: { $0.date < $1.date });
        
        let average = entries.map { $0.data?.count ?? 0 }.reduce(0, +) / entries.count;
        
        print("Widget: Data load successful. \(entries.count) days loaded, average of \(average) bills per snapshot.");
        return Timeline(entries: entries, policy: .atEnd )
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct UpcomingBillsEntry: TimelineEntry {
    let date: Date;
    let data: [UpcomingBill]?;
}

//
//  UpcomingBills.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI
import CoreData

struct UpcomingBillsView : View {
    @State private var loadedBills: [UpcomingBill]? = nil;
    
    @QuerySelection<Bill> private var bills;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.billsDateManager) private var billsDateManager;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";

    private nonisolated func loadBills() async -> [UpcomingBill] {
        return await Task { @MainActor in
            var result: [UpcomingBill] = [];
            for bill in bills.data {
                let date = billsDateManager.fetchAgainst(id: bill.objectID)
                if case .dueOn(let date) = date {
                    result.append(
                        UpcomingBill(
                            name: bill.name,
                            amount: bill.amount,
                            dueDate: date
                        )
                    )
                }
            }
            
            return result.sorted(using: KeyPathComparator(\.dueDate, order: .forward))
        }.value;
    }
    
    var body: some View {
        LoadableView($loadedBills, process: loadBills) { loaded in
            #if os(macOS)
            Table(loaded) {
                TableColumn("Name", value: \.name)
                    .width(min: 120, ideal: 140, max: nil)
                
                TableColumn("Due Date") {
                    Text($0.dueDate.formatted(date: .abbreviated, time: .omitted))
                }.width(min: 140, ideal: 150, max: nil)
                
                TableColumn("Amount") {
                    Text($0.amount, format: .currency(code: currencyCode))
                }.width(min: 120, ideal: 140, max: nil)
                    .alignment(.numeric)
                
            }
            #else
            if loaded.isEmpty {
                Text("There are no upcoming bills")
                    .italic()
            }
            else {
                List(loaded) { bill in
                    HStack {
                        Text(bill.name)
                        Spacer()
                        Text(bill.dueDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            #endif
        }
    }
}

#Preview(traits: .sampleData) {
    UpcomingBillsView()
        .padding()
}

//
//  UpcomingBills.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI
import SwiftData

struct UpcomingBillsView : View {
    @State private var loadedBills: [UpcomingBill]? = nil;
    
    @Environment(\.modelContext) private var modelContext;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @MainActor
    private func makeManager() -> UpcomingBillsWidgetManager? {
        return try? .init(context: modelContext)
    }
    
    @MainActor
    private func loadBills() async -> [UpcomingBill] {
        guard let manager = await MainActor.run(body: makeManager) else {
            return []
        }
        
        return manager.determineUpcomingBills(for: .now).bills
    }
    
    var body: some View {
        LoadableView($loadedBills, process: loadBills, onLoad: { loaded in
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
        })
    }
}

#Preview {
    DebugContainerView {
        UpcomingBillsView()
            .padding()
    }
}

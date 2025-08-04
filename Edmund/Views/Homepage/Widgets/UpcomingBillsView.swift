//
//  UpcomingBills.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI
import SwiftData
import EdmundCore

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
            List(loaded) { bill in
                HStack {
                    Text(bill.name)
                    Spacer()
                    Text(bill.amount, format: .currency(code: currencyCode))
                    Text("on", comment: "$_ on [date]")
                    Text(bill.dueDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
        })
    }
}

#Preview {
    DebugContainerView {
        UpcomingBillsView()
            .padding()
    }
}

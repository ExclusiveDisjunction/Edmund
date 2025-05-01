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
    @Query private var bills: [Bill];
    @Query private var utilities: [Utility];
    @State private var loadedBills: [UpcomingBill]? = nil;
    private var allBills: [any BillBase] {
        bills + utilities
    }
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func loadBills() -> [UpcomingBill] {
        .init()
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
    UpcomingBillsView()
        .padding()
        .modelContainer(Containers.debugContainer)
}

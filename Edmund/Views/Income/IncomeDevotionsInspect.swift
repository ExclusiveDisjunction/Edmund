//
//  BudgetDevotionsInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

struct IncomeDevotionsInspect : View {
    var data: IncomeDivision
    @State private var selection: Set<IncomeDevotion.ID> = .init();
    @State private var closeLook: IncomeDevotion? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func computedAmount(_ target: IncomeDevotion) -> Decimal {
        switch target.kind {
            case .amount(let a): a
            case .percent(let p): p  * data.amount
            case .remainder: data.perRemainderAmount
        }
    }
    
    @ViewBuilder
    private var fullSize: some View {
        Table(data.devotions, selection: $selection) {
            TableColumn("Name") { row in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(row.name)
                        Spacer()
                        Text(computedAmount(row), format: .currency(code: currencyCode))
                    }.swipeActions(edge: .trailing) {
                        Button {
                            closeLook = row
                        } label: {
                            Label("Close Look", systemImage: "magnifyingglass")
                        }.tint(.green)
                    }
                }
                else {
                    Text(row.name)
                }
            }
            TableColumn("Devotion") { row in
                switch row.kind {
                    case .amount(let a): Text(a, format: .currency(code: currencyCode))
                    case .percent(let p): Text(p, format: .percent)
                    case .remainder: Text("-")
                }
            }
            TableColumn("Amount") { row in
                Text(computedAmount(row), format: .currency(code: currencyCode))
            }
            TableColumn("Group") { row in
                Text(row.group.display)
            }
            TableColumn("Destination") { row in
                ElementDisplayer(value: row.account)
            }
#if os(macOS)
            .width(150)
#endif
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Total Income:")
                Text(data.amount, format: .currency(code: currencyCode))
                
                Spacer()
                
                Text("Money Left:", comment: "This in context is the amount of money left from the income of the divider, minus all devotions. This is similar to variance.")
                Text(data.moneyLeft, format: .currency(code: currencyCode))
            }
            
            fullSize
        }.padding()
            .sheet(item: $closeLook) { item in
                DevotionCloseLook(data: item, owner: data)
            }
    }
}

#Preview {
    @Previewable @Query var income: [IncomeDivision];
    DebugContainerView {
        IncomeDevotionsInspect(data: income[0] )
    }
}

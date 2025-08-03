//
//  BudgetDevotionsInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDevotionsInspect : View {
    var data: IncomeDivision
    @State private var selection: Set<AnyDevotion.ID> = .init();
    @State private var closeLook: AnyDevotion? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func computedAmount(_ target: AnyDevotion) -> Decimal {
        switch target {
            case .amount(let a): a.amount
            case .percent(let p): p.amount * data.amount
            case .remainder(_): data.remainderValue
            default: .nan
        }
    }
    
    @ViewBuilder
    private var fullSize: some View {
        Table(data.allDevotions, selection: $selection) {
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
                switch row {
                    case .amount(let a): Text(a.amount, format: .currency(code: currencyCode))
                    case .percent(let p): Text(p.amount, format: .percent)
                    case .remainder(_): Text("Remainder")
                    default: Text("internalError")
                }
            }
            TableColumn("Amount") { row in
                Text(computedAmount(row), format: .currency(code: currencyCode))
            }
            TableColumn("Group") { row in
                Text(row.group.display)
            }
            TableColumn("Destination") { row in
                CompactNamedPairInspect(row.account)
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
                
                Text("Amount Free:", comment: "This in context is the amount of money left from the income of the divider, minus all devotions. This is similar to variance.")
                Text(data.variance, format: .currency(code: currencyCode))
            }
            
            fullSize
        }.padding()
            .sheet(item: $closeLook) { item in
                AnyDevotionCloseLook(data: item, owner: data)
            }
    }
}

#Preview {
    DebugContainerView {
        IncomeDevotionsInspect(data: try! .getExampleBudget())
    }
}

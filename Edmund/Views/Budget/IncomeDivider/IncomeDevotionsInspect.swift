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
    private var compact: some View {
        VStack {
            HStack {
                Text("Name")
                    .font(.subheadline)
                    .bold()
                    .padding(.leading)
                
                Spacer()
                
                Text("Amount")
                    .font(.subheadline)
                    .bold()
            }.padding([.leading, .trailing, .top])
            
            List(data.allDevotions, selection: $selection) { devotion in
                HStack {
                    Text(devotion.name)
                    Spacer()
                    Text(computedAmount(devotion), format: .currency(code: currencyCode))
                }
            }
        }
    }
    
    @ViewBuilder
    private var fullSize: some View {
        Table(data.allDevotions, selection: $selection) {
            TableColumn("Name", value: \.name)
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
            
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                fullSize
            }
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        IncomeDevotionsInspect(data: try! .getExampleBudget())
    }
}

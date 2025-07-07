//
//  DevotionGroupsGraph.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/27/25.
//

import SwiftUI
import SwiftData
import Charts
import EdmundCore

struct DevotionGroupsGraph: View {
    struct ChartRow : Identifiable {
        init(_ group: DevotionGroup, _ value: Decimal) {
            self.group = group
            self.value = value
        }
        var group: DevotionGroup;
        var value: Decimal;
        
        var id: DevotionGroup { group }
    }
    
    public init(from: BudgetInstance, isSheet: Bool = true) {
        self.isSheet = isSheet
        
        let all = from.allDevotions;
        var data: [DevotionGroup : Decimal] = [:];
        var total: Decimal = 0;
        for item in all {
            let amount: Decimal = switch item {
                case .amount(let a): a.amount
                case .percent(let p): p.amount * from.amount
                case .remainder(_): from.remainderValue
                default: .nan
            }
            
            data[item.group, default: 0.0] += amount;
            total += amount;
        }
        
        // Turns it into a percent
        self.data = data.map { .init($0.key, $0.value / total ) }
    }
    public init(data: [ChartRow], isSheet: Bool = true) {
        self.data = data
        self.isSheet = isSheet
    }
    
    private let data: [ChartRow];
    let isSheet: Bool;
    
    @Environment(\.dismiss) private var dismiss;
    
    var body: some View {
        VStack {
            HStack {
                Text("Devotions Chart")
                    .font(.title3)
                
                Spacer()
            }
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Percentage", item.value),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Group", item.group.asString))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    if item.value > 0.05 {
                        Text("\(item.group.asString): \(item.value, format: .percent.precision(.fractionLength(0)))")
                    }
                }
            }.frame(minHeight: 250)
            
            if isSheet {
                Spacer()
                
                HStack {
                    Spacer()
                    Button("Ok", action: { dismiss() } )
                        .buttonStyle(.borderedProminent)
                }
            }
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        DevotionGroupsGraph(from: try! .getExampleBudget(), isSheet: false)
    }
}

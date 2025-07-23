//
//  BudgetDevotionsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDevotionsEditor : View {
    @Bindable var snapshot: IncomeDividerInstanceSnapshot;
    @State private var selection: Set<AnyDevotionSnapshot.ID> = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var compact: some View {
        List($snapshot.devotions, selection: $selection) { $devotion in
            
        }
    }
    
    @ViewBuilder
    private var fullSize: some View {
        Table($snapshot.devotions, selection: $selection) {
            TableColumn("Name") { $dev in
                TextField("", text: $dev.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            TableColumn("Devotion") { $dev in
                switch dev {
                    case .amount(let a): CurrencyField(a.amount)
                    case .percent(let p): PercentField(p.amount)
                    default: Text("internalError")
                }
            }
            
            TableColumn("Amount") { $dev in
                switch dev {
                    case .amount(let a): Text(a.amount.rawValue, format: .currency(code: currencyCode))
                    case .percent(let p): Text(p.amount.rawValue * snapshot.amount.rawValue, format: .currency(code: currencyCode))
                    default: Text("internalError")
                }
            }
            
            TableColumn("Group") { $dev in
                Picker("", selection: $dev.group) {
                    ForEach(DevotionGroup.allCases) { group in
                        Text(group.display).tag(group)
                    }
                }
            }
            
            TableColumn("Destination") { $dev in
                NamedPairPicker($dev.account)
            }
            .width(160)
        }
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            compact
                .padding()
        }
        else {
            fullSize
                .padding()
        }
    }
}

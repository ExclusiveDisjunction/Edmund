//
//  AnyDevotionSnapshotCloseLook.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/23/25.
//

import SwiftUI
import EdmundCore

struct AmountDevotionSnapshotCloseLook : View {
    @Bindable var devotion: AmountDevotionSnapshot
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 70;
    private let maxWidth: CGFloat = 80;
#else
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#endif
    
    var body: some View {
        Grid {
            GridRow {
                Text("Name:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("", text: $devotion.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            GridRow {
                Text("Devotion:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                CurrencyField(devotion.amount)
            }
            
            GridRow {
                Text("Group:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                Picker("", selection: $devotion.group) {
                    ForEach(DevotionGroup.allCases) { group in
                        Text(group.display).tag(group)
                    }
                }.labelsHidden().pickerStyle(.segmented)
            }
            
            GridRow {
                Text("Account:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                NamedPairPicker($devotion.account)
            }
        }
    }
}

struct PercentDevotionSnapshotCloseLook : View {
    let snapshot: IncomeDivisionSnapshot;
    @Bindable var devotion: PercentDevotionSnapshot;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif

    var body: some View {
        Grid {
            GridRow {
                Text("Name:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("", text: $devotion.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            GridRow {
                Text("Devotion:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                PercentField(devotion.amount)
            }
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(devotion.amount.rawValue * snapshot.amount.rawValue, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            
            GridRow {
                Text("Group:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                Picker("", selection: $devotion.group) {
                    ForEach(DevotionGroup.allCases) { group in
                        Text(group.display).tag(group)
                    }
                }.labelsHidden().pickerStyle(.segmented)
            }
            
            GridRow {
                Text("Account:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                NamedPairPicker($devotion.account)
            }
        }
    }
}

struct AnyDevotionSnapshotCloseLook : View {
    let snapshot: IncomeDivisionSnapshot;
    let devotion: AnyDevotionSnapshot;
    
    @Environment(\.dismiss) private var dismiss;
    
    var body: some View {
        VStack {
            HStack {
                Text("Devotion Close Look")
                    .font(.title3)
                
                Spacer()
            }
            
            switch devotion {
                case .amount(let a): AmountDevotionSnapshotCloseLook(devotion: a)
                case .percent(let p): PercentDevotionSnapshotCloseLook(snapshot: snapshot, devotion: p)
                default: Text("internalError")
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        let snapshot = try! IncomeDivision.getExampleBudget().makeSnapshot()
        let devotion = snapshot.devotions[0];
        AnyDevotionSnapshotCloseLook(snapshot: snapshot, devotion: devotion)
    }
}

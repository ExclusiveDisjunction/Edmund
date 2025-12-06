//
//  AnyDevotionSnapshotCloseLook.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/23/25.
//

import SwiftUI
import SwiftData

struct DevotionSnapshotCloseLook : View {
    let snapshot: IncomeDivisionSnapshot;
    @Bindable var devotion: IncomeDevotionSnapshot;
    
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    var body: some View {
        VStack {
            HStack {
                Text("Devotion Close Look")
                    .font(.title3)
                
                Spacer()
            }
            
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
                    
                    switch devotion.kind {
                        case .amount(let a): CurrencyField(a)
                        case .percent(let b): PercentField(b)
                        case .remainder: HStack {
                            Text("Remainder")
                            Spacer()
                        }
                    }
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        let amount = switch devotion.kind {
                            case .amount(let a): a.rawValue
                            case .percent(let b): b.rawValue * snapshot.amount.rawValue
                            case .remainder: snapshot.perRemainderAmount
                        }
                        
                        Text(amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Group:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    EnumPicker(value: $devotion.group).pickerStyle(.segmented)
                }
                
                GridRow {
                    Text("Account:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($devotion.account)
                }
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
    @Previewable @Query var divisions: [IncomeDivision];
    
    DebugContainerView {
        let snapshot = divisions[0].makeSnapshot()
        let devotion = snapshot.devotions[0];
        DevotionSnapshotCloseLook(snapshot: snapshot, devotion: devotion)
    }
}

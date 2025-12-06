//
//  AnyDevotionCloseLook.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import SwiftUI

struct DevotionCloseLook : View {
    var data: IncomeDevotion
    var owner: IncomeDivision
    
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    private func computedAmount(_ target: IncomeDevotion) -> Decimal {
        switch target.kind {
            case .amount(let a): a
            case .percent(let p): p * owner.amount
            case .remainder: owner.perRemainderAmount
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Devotion Close Look")
                    .font(.title2)
                
                Spacer()
            }.padding(.bottom)
            
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.name)
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Devotion:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        switch data.kind {
                            case .amount(let a): Text(a, format: .currency(code: currencyCode))
                            case .percent(let p): Text(p, format: .percent)
                            case .remainder: Text("-")
                        }
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(computedAmount(data), format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Group:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.group.display)
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Destination:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        ElementDisplayer(value: data.account)
                        
                        Spacer()
                    }
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

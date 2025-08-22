//
//  SplitChoicePicker.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI

enum SplitKind {
    case vSplit, hSplit
}

struct SplitChoicePicker : View {
    let kind: SplitKind
    let minor: MinorHomepageOrder
    @Binding var sectorA: WidgetChoice
    @Binding var sectorB: WidgetChoice
    
    @ViewBuilder
    private var content: some View {
        ChoicePicker(choice: _sectorA)
        if minor == .half {
            ChoicePicker(choice: _sectorB)
        }
    }
    
    var body: some View {
        if kind == .hSplit {
            VStack {
                content
            }
        }
        else {
            HStack {
                content
            }
        }
    }
}

#Preview {
    var a = WidgetChoice.bills, b = WidgetChoice.simpleBalances;
    let aBind = Binding(get: {a}, set: {a = $0}), bBind = Binding(get: {b}, set: {b = $0});
    
    SplitChoicePicker(kind: .vSplit, minor: .half, sectorA: aBind, sectorB: bBind)
        .padding()
}

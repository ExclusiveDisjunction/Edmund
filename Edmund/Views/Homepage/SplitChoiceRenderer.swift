//
//  SplitChoiceRenderer.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI

struct SplitChoiceRenderer : View {
    let kind: SplitKind
    let minor: MinorHomepageOrder
    let sectorA: WidgetChoice
    let sectorB: WidgetChoice
    
    var body: some View {
        if minor == .full {
            ChoiceRenderer(choice: sectorA)
        }
        else {
            if kind == .hSplit {
                VStack {
                    ChoiceRenderer(choice: sectorA)
                    ChoiceRenderer(choice: sectorB)
                }
            }
            else {
                HStack {
                    ChoiceRenderer(choice: sectorA)
                    ChoiceRenderer(choice: sectorB)
                }
            }
        }
    }
}

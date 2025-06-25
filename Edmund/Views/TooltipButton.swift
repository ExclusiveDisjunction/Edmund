//
//  TooltipButton.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/22/25.
//

import SwiftUI

public struct TooltipButton : View {
    public init(_ text: LocalizedStringKey) {
        self.text = text
    }
    
    public let text: LocalizedStringKey;
    
    @State private var showTooltip = false;
    
    public var body: some View {
        Button(action: {
            showTooltip = true
        }) {
            Image(systemName: "questionmark.circle")
        }.popover(isPresented: $showTooltip) {
            Text(text)
                .padding()
        }
        .buttonStyle(.borderless)
    }
}

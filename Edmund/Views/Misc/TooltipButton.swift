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
            ScrollView {
                Text(text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding()
            }
            .frame(maxWidth: 300, maxHeight: 300)
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    VStack {
        Spacer()
        
        HStack {
            Spacer()
            TooltipButton("Here is some small text")
            
            TooltipButton("Large Text: \(String(repeating: "Hello! ", count: 100))")
            Spacer()
        }.padding()
        
        Spacer()
    }
}

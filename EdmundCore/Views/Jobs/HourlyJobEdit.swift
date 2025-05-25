//
//  HourlyJobEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftUI

public struct HourlyJobEdit : View, ElementEditorView {
    public typealias For = HourlyJob
    
    public init(_ data: HourlyJobSnapshot) {
        self.snapshot = data
    }
    
    @Bindable private var snapshot: HourlyJobSnapshot;
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 60;
    private let labelMaxWidth: CGFloat = 70;
#else
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 85;
#endif
    
    public var body: some View {
        Grid {
            Text("Company:")
                .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
            
            TextField("Company", text: $snapshot.company)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    HourlyJobEdit(.init())
}

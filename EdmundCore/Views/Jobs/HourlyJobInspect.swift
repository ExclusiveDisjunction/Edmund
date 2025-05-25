//
//  HourlyJobView.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftUI

public struct HourlyJobInspect : View, ElementInspectorView {
    public typealias For = HourlyJob
    
    public init(_ data: HourlyJob) {
        self.data = data
    }
    
    private var data: HourlyJob
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 60;
    private let labelMaxWidth: CGFloat = 70;
#else
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 85;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Company:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
            }
        }
    }
}

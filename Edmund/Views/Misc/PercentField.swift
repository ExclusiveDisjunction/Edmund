//
//  PercentField.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import SwiftUI
import EdmundCore

public struct PercentField : View {
    public init(_ on: PercentValue) {
        self.on = on;
    }
    
    @Bindable public var on: PercentValue;
    @FocusState private var focus: Bool;
    
    public var body: some View {
        TextField("", text: $on.raw)
            .textFieldStyle(.roundedBorder)
            .onAppear {
                on.format()
            }
            .onSubmit {
                on.format()
            }
            .onChange(of: on.raw) { _, newValue in
                let filter = newValue.filter { "-0123456789.".contains($0) }
                
                if let parsed = Decimal(string: filter) {
                    on.rawValue = parsed / 100
                }
            }
            .focused($focus)
            .onChange(of: focus) { _, newValue in
                if !newValue {
                    on.format()
                }
            }
    }
}

#Preview {
    let value: PercentValue = .init();
    
    PercentField(value)
        .padding()
}

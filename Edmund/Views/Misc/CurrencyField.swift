//
//  CurrencyField.swift
//  Edmund
//
//  Created by Hollan on 5/19/25.
//

import SwiftUI
import EdmundCore

/// A view that takes in a `CurrencyValue` and allows for user editing of that value. This will update the internal `rawValue` as modifications are submitted.
public struct CurrencyField : View {
    public init(_ on: CurrencyValue) {
        self.on = on;
    }
    
    @Bindable public var on: CurrencyValue;
    @FocusState private var focus: Bool;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public var body: some View {
        TextField("", text: $on.raw)
            .textFieldStyle(.roundedBorder)
            .onAppear {
                on.format(context: currencyCode)
            }
            .onChange(of: on.raw) { _, newValue in
                let filter = newValue.filter { "-0123456789.".contains($0) }

                if let parsed = Decimal(string: filter) {
                    on.rawValue = parsed
                }
            }
            .focused($focus)
            .onChange(of: focus) { _, newValue in
                if !newValue {
                    on.format(context: currencyCode)
                }
            }
#if os(iOS)
            .keyboardType(.decimalPad)
#endif
    }
}

#Preview {
    let data: CurrencyValue = .init(rawValue: 100.0);
    
    VStack {
        CurrencyField(data)
        HStack {
            Text("Extracted:")
            Text(data.rawValue, format: .currency(code: "USD"))
        }
        TextField("", text: Binding.constant(""))
    }.padding()
}

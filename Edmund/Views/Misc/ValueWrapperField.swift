//
//  ValueWrapperField.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/2/25.
//

import SwiftUI
import EdmundCore

struct ValueWrapperField<T> : View where T: ValueWrapper {
    let isNumeric: Bool;
    @Bindable var over: T;
    @Binding var context: T.Context;
    @FocusState private var focus: Bool;
    
    var body: some View {
        TextField("", text: $over.raw)
            .textFieldStyle(.roundedBorder)
            .onAppear {
                over.format(context: context)
            }
            .onSubmit {
                over.format(context: context)
            }
            .onChange(of: over.raw) { _, _ in
                over.rawChanged()
            }
            .focused($focus)
            .onChange(of: focus) { _, newValue in
                if !newValue {
                    over.format(context: context)
                }
            }
        #if os(iOS)
            .keyboardType(isNumeric ? .decimalPad : .default)
        #endif
    }
}

struct CurrencyField : View {
    init(_ over: CurrencyValue) {
        self.over = over
    }
    
    @Bindable private var over : CurrencyValue;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        ValueWrapperField(isNumeric: true, over: over, context: $currencyCode)
    }
}

struct PercentField : View {
    init(_ over: PercentValue) {
        self.over = over
    }
    
    @Bindable private var over: PercentValue;
    
    var body: some View {
        ValueWrapperField(isNumeric: true, over: over, context: .constant(()))
    }
}

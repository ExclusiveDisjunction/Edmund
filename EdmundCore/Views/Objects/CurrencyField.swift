//
//  CurrencyField.swift
//  Edmund
//
//  Created by Hollan on 5/19/25.
//

import SwiftUI

@Observable
public final class CurrencyValue : Comparable, Equatable, Hashable, RawRepresentable {
    public typealias RawValue = Decimal;
    
    public init(rawValue: Decimal = 0.0) {
        self.rawValue = rawValue;
        self.raw = "";
    }
    public var rawValue: Decimal;
    var raw: String;
    
    public static func <(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    public static func <(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.rawValue < rhs
    }
    public static func <=(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.rawValue <= rhs
    }
    public static func >(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.rawValue > rhs
    }
    public static func >=(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.rawValue >= rhs
    }
    public static func ==(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.rawValue == rhs
    }
    public static func ==(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
        hasher.combine(raw)
    }
    
    public func format(_ currencyCode: String) {
        let formatter = NumberFormatter();
        formatter.numberStyle = .currency;
        formatter.currencyCode = currencyCode
        self.raw = formatter.string(from: rawValue as NSDecimalNumber) ?? "";
    }
}

public struct CurrencyField : View {
    public init(_ on: Binding<CurrencyValue>, label: LocalizedStringKey = "") {
        self._on = on;
        self.label = label;
    }
    
    @Binding public var on: CurrencyValue;
    @FocusState private var focus: Bool;
    private let label: LocalizedStringKey;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public var body: some View {
        TextField(self.label, text: $on.raw)
            .textFieldStyle(.roundedBorder)
            .onAppear {
                on.format(currencyCode)
            }
            .onChange(of: on.raw) { _, newValue in
                let filter = newValue.filter { "-0123456789.".contains($0) }

                if let parsed = Decimal(string: filter) {
                    on.rawValue = parsed
                }
            }.focusable()
            .focused($focus)
            .onChange(of: focus) { _, newValue in
                if !newValue {
                    on.format(currencyCode)
                }
            }
#if os(iOS)
            .keyboardType(.decimalPad)
#endif
    }
}

#Preview {
    var data: CurrencyValue = .init(rawValue: 100.0);
    let binding = Binding(get: { data }, set: { data = $0 } );
    
    VStack {
        CurrencyField(binding, label: "Testing")
        HStack {
            Text("Extracted:")
            Text(data.rawValue, format: .currency(code: "USD"))
        }
        TextField("", text: Binding.constant(""))
    }.padding()
}

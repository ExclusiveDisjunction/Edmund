//
//  CurrencyField.swift
//  Edmund
//
//  Created by Hollan on 5/19/25.
//

import SwiftUI

@Observable
public class CurrencyValue : Comparable, Equatable, Hashable {
    public init(_ amount: Decimal = 0.0) {
        self.amount = amount;
        self.raw = "";
    }
    public var amount: Decimal;
    var raw: String;
    
    public static func <(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.amount < rhs.amount
    }
    public static func <(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.amount < rhs
    }
    public static func <=(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.amount <= rhs
    }
    public static func >(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.amount > rhs
    }
    public static func >=(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.amount >= rhs
    }
    public static func ==(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.amount == rhs
    }
    public static func ==(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.amount == rhs.amount
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(raw)
    }
    
    public func format(_ currencyCode: String) {
        let formatter = NumberFormatter();
        formatter.numberStyle = .currency;
        formatter.currencyCode = currencyCode
        self.raw = formatter.string(from: amount as NSDecimalNumber) ?? "";
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
                    on.amount = parsed
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
    var data: CurrencyValue = .init(100.0);
    let binding = Binding(get: { data }, set: { data = $0 } );
    
    VStack {
        CurrencyField(binding, label: "Testing")
        HStack {
            Text("Extracted:")
            Text(data.amount, format: .currency(code: "USD"))
        }
        TextField("", text: Binding.constant(""))
    }.padding()
}

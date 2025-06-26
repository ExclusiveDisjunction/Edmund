//
//  CurrencyField.swift
//  Edmund
//
//  Created by Hollan on 5/19/25.
//

import SwiftUI

/// A data type that encapsulates a `Decimal` value, and will update the `Decimal` value based off of a raw string.
@Observable
public final class CurrencyValue : Comparable, Equatable, Hashable, RawRepresentable {
    public typealias RawValue = Decimal;
    
    /// Creates the `CurrencyValue` from a predetermined value.
    public init(rawValue: Decimal = 0.0) {
        self.rawValue = rawValue;
        self.raw = "";
    }
    public var rawValue: Decimal;
    /// The raw string being used to store the current value.
    fileprivate var raw: String;
    
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
    public static func !=(lhs: CurrencyValue, rhs: Decimal) -> Bool {
        lhs.rawValue != rhs
    }
    public static func ==(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
        hasher.combine(raw)
    }
    
    /// Converts the internal `rawValue` into a displayable string.
    fileprivate func format(_ currencyCode: String) {
        let formatter = NumberFormatter();
        formatter.numberStyle = .currency;
        formatter.currencyCode = currencyCode
        self.raw = formatter.string(from: rawValue as NSDecimalNumber) ?? "";
    }
}

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
                on.format(currencyCode)
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
                    on.format(currencyCode)
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

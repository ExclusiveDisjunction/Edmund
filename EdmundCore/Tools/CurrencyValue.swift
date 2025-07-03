//
//  CurrencyValue.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import Foundation

/// A data type that encapsulates a `Decimal` value, and will update the `Decimal` value based off of a raw string.
@Observable
public final class CurrencyValue : ValueWrapper {
    public typealias Context = String;
    public typealias RawValue = Decimal;
    
    /// Creates the `CurrencyValue` from a predetermined value.
    public init(rawValue: Decimal = 0.0) {
        self.rawValue = rawValue;
        self.raw = "";
    }
    public var rawValue: Decimal;
    /// The raw string being used to store the current value.
    public var raw: String;
    
    public static func <(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    public static func ==(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
        hasher.combine(raw)
    }
    
    /// Converts the internal `rawValue` into a displayable string.
    public func format(context: String) {
        let formatter = NumberFormatter();
        formatter.numberStyle = .currency;
        formatter.currencyCode = context
        self.raw = formatter.string(from: rawValue as NSDecimalNumber) ?? "";
    }
    public func rawChanged() {
        let filter = raw.filter { "-0123456789.".contains($0) }
        
        if let parsed = Decimal(string: filter) {
            self.rawValue = parsed
        }
    }
}

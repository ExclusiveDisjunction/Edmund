//
//  PercentValue.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import Foundation

@Observable
public final class PercentValue : ValueWrapper {
    public typealias Context = ();
    public typealias RawValue = Decimal;
    
    public init(rawValue: Decimal = 0.0) {
        self.rawValue = rawValue;
        self.raw = "";
    }
    
    public var rawValue: Decimal;
    public var raw: String;
    
    public static func <(lhs: PercentValue, rhs: PercentValue) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    public static func ==(lhs: PercentValue, rhs: PercentValue) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
        hasher.combine(raw)
    }
    
    /// Converts the internal `rawValue` into a displayable string.
    public func format(context: Context) {
        let formatter = NumberFormatter();
        formatter.numberStyle = .percent;
        formatter.maximumFractionDigits = 3;
        formatter.minimumFractionDigits = 0;
        self.raw = formatter.string(from: rawValue as NSDecimalNumber) ?? "";
    }
    public func rawChanged() {
        let filter = raw.filter { "-0123456789.".contains($0) }
        
        if let parsed = Decimal(string: filter) {
            self.rawValue = parsed
        }
    }
}

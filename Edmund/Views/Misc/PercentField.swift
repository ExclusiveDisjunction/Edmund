//
//  PercentField.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import SwiftUI

@Observable
public final class PercentValue : Comparable, Equatable, Hashable, RawRepresentable {
    public typealias RawValue = Decimal;
    
    public init(rawValue: Decimal = 0.0) {
        self.rawValue = rawValue;
        self.raw = "";
    }
    
    public var rawValue: Decimal;
    fileprivate var raw: String;
    
    public static func <(lhs: PercentValue, rhs: PercentValue) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    public static func <(lhs: PercentValue, rhs: Decimal) -> Bool {
        lhs.rawValue < rhs
    }
    public static func <=(lhs: PercentValue, rhs: Decimal) -> Bool {
        lhs.rawValue <= rhs
    }
    public static func >(lhs: PercentValue, rhs: Decimal) -> Bool {
        lhs.rawValue > rhs
    }
    public static func >=(lhs: PercentValue, rhs: Decimal) -> Bool {
        lhs.rawValue >= rhs
    }
    public static func ==(lhs: PercentValue, rhs: Decimal) -> Bool {
        lhs.rawValue == rhs
    }
    public static func !=(lhs: PercentValue, rhs: Decimal) -> Bool {
        lhs.rawValue != rhs
    }
    public static func ==(lhs: PercentValue, rhs: PercentValue) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
        hasher.combine(raw)
    }
    
    /// Converts the internal `rawValue` into a displayable string.
    fileprivate func format() {
        let formatter = NumberFormatter();
        formatter.numberStyle = .percent;
        formatter.maximumFractionDigits = 3;
        formatter.minimumFractionDigits = 0;
        self.raw = formatter.string(from: rawValue as NSDecimalNumber) ?? "";
    }
}

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

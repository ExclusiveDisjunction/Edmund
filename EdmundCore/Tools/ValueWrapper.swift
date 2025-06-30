//
//  ValueWrapper.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

/// A type that supports the reading & writing of a 'raw' string, that can be converted to the internal storage.
/// This protocol enforces that the type can be hashed and be compared (with itself & the raw value).
/// Use this for a UI based-feature that may cause instability with direct formatters.
public protocol ValueWrapper : Comparable, Equatable, Hashable, RawRepresentable {
    associatedtype Context;
    
    var raw: String { get set }
    
    func format(context: Context);
}
public extension ValueWrapper where RawValue: Comparable {
    static func <(lhs: Self, rhs: RawValue) -> Bool {
        lhs.rawValue < rhs
    }
    static func <=(lhs: Self, rhs: RawValue) -> Bool {
        lhs.rawValue <= rhs
    }
    static func >(lhs: Self, rhs: RawValue) -> Bool {
        lhs.rawValue > rhs
    }
    static func >=(lhs: Self, rhs: RawValue) -> Bool {
        lhs.rawValue >= rhs
    }
    static func ==(lhs: Self, rhs: RawValue) -> Bool {
        lhs.rawValue == rhs
    }
    static func !=(lhs: Self, rhs: RawValue) -> Bool {
        lhs.rawValue != rhs
    }
}

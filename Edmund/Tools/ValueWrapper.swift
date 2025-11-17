//
//  ValueWrapper.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import Observation

/// A type that supports the reading & writing of a 'raw' string, that can be converted to the internal storage.
/// This protocol enforces that the type can be hashed and be compared (with itself & the raw value).
/// Use this for a UI based-feature that may cause instability with direct formatters.
public protocol ValueWrapper : AnyObject, Comparable, Equatable, Hashable, RawRepresentable, Observable {
    /// A passed in type that can be used to help with converting from the `rawValue` to the `raw` string.
    associatedtype Context;
    
    /// The current raw presented string for the UI.
    var raw: String { get set }
    
    /// Converts `rawValue`, using `context` into the internal `raw` string instance.
    func format(context: Context);
    /// Signals that `raw` has been changed, and the `rawValue` variable needs to be changed.
    func rawChanged();
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

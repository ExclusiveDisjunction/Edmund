//
//  BoundPairTree.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/30/25.
//

import Foundation

public struct DuplicateNameError : Error, Sendable, CustomStringConvertible{
    public init(_ name: String) {
        self.name = name
    }
    
    public let name: String;
    
    public var localizedDescription: String {
        "The name \(name) is not unique"
    }
    public var description: String {
        "Duplicate name: \(name)"
    }
}

public struct ElementLocator<T> where T: NamedElement, T: Identifiable, T: AnyObject {
    public init<C>(data: C) throws(DuplicateNameError)
    where C: Collection, C.Element == T {
        var result: [String: T] = [:];
        for item in data {
            if let _ = result[item.name] {
                throw DuplicateNameError(item.name)
            }
            else {
                result[item.name] = item
            }
        }
        self.data = result
    }
    
    private var data: [String : T];
    
    public subscript(position: String) -> T? {
        _read {
            yield self.data[position]
        }
    }
    
    public mutating func getOrInsert(name: String) -> T
    where T: DefaultableElement {
        if let target = self[name] {
            return target
        }
        else {
            let new = T();
            new.name = name
            
            self.data[name] = new;
            return new;
        }
    }
}
extension ElementLocator : Sendable where T: Sendable { }

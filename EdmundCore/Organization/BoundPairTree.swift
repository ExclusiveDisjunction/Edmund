//
//  BoundPairTree.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/30/25.
//

import Foundation

public struct DuplicateIdError<T> : Error, Sendable, CustomStringConvertible where T: Hashable, T: Sendable {
    public init(_ id: T) {
        self.id = id
    }
    
    public let id: T;
    
    public var localizedDescription: String {
        "The id \(id) is not unique"
    }
    public var description: String {
        "Duplicate ID: \(id)"
    }
}
public enum ParentChildID : Hashable, Sendable, CustomStringConvertible {
    case parent(String)
    case child(BoundPairID)
    
    public var description: String {
        switch self {
            case .parent(let p): "Parent: '\(p)'"
            case .child(let c): "Child: '\(c)'"
        }
    }
}

public struct BoundPairTreeRow<T> where T: BoundPairParent, T.C.P == T {
    internal init<C>(target: T, children: C) throws(DuplicateIdError<BoundPairID>) where C: Collection, C.Element == T.C {
        var childrenDict: [String : T.C] = [:];
        for item in children {
            guard !childrenDict.keys.contains(item.id.name) else {
                throw .init(item.id)
            }
            
            childrenDict[item.name] = item
        }
        
        self.init(target: target, children: childrenDict)
    }
    internal init(target: T, children: Dictionary<String, T.C>) {
        self.target = target
        self.children = children
    }
    
    public let target: T;
    fileprivate var children: Dictionary<String, T.C>;
    
    public subscript(position: String) -> T.C? {
        _read {
            yield children[position]
        }
    }
}

public struct BoundPairTree<T> where T: BoundPairParent, T.C.P == T {
    public init<C>(data: C) throws(DuplicateIdError<ParentChildID>) where C: Collection, C.Element == T {
        var computed: [String : BoundPairTreeRow<T>] = [:];
        for item in data {
            guard !computed.keys.contains(item.id) else {
                print("Duplicate parent: \(item.name)")
                throw .init(.parent(item.id))
            }
            
            do {
                computed[item.id] = try BoundPairTreeRow(target: item, children: item.children)
            }
            catch let e {
                throw .init(.child(e.id))
            }
        }
        
        self.init(data: computed)
    }
    internal init(data: Dictionary<String, BoundPairTreeRow<T>>) {
        self.data = data
    }
    
    private var data: Dictionary<String, BoundPairTreeRow<T>>
    
    public subscript(position: String) -> T? {
        _read {
            yield self.data[position]?.target
        }
    }
    public subscript(parent: String, child: String) -> T.C? {
        _read {
            if let row = data[parent] {
                yield row[child]
            }
            else {
                yield nil
            }
        }
    }
    
    public mutating func getOrInsert(name: String) -> T {
        if let target = self[name] {
            return target
        }
        else {
            var new = T();
            new.name = name
            
            self.data[name] = .init(target: new, children: .init());
            return new;
        }
    }
    public mutating func getOrInsert(parent: String, child: String) -> T.C {
        if let target = self.data[parent]?.children[child] {
            return target
        }
        else if var target = self.data[parent] {
            var new = T.C(parent: target.target)
            new.name = child
            
            target.children[child] = new
            return new
        }
        else {
            var newParent = T()
            newParent.name = parent
            var newRow = try! BoundPairTreeRow(target: newParent, children: [])
            var newChild = T.C(parent: newParent)
            newChild.name = child
            newRow.children[child] = newChild;
            
            self.data[parent] = newRow;
            
            return newChild
        }
    }
}

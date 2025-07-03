//
//  BoundPairTree.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/30/25.
//

import Foundation

public struct BoundPairTreeRow<T> where T: BoundPairParent, T.C.P == T {
    internal init<C>(target: T, children: C) where C: Collection, C.Element == T.C{
        let childrenDict: [String : T.C] = .init(uniqueKeysWithValues: children.map { ($0.name, $0) } );
        self.init(target: target, children: childrenDict)
    }
    internal init(target: T, children: Dictionary<String, T.C>) {
        self.target = target
        self.children = children
    }
    
    public let target: T;
    private var children: Dictionary<String, T.C>;
    
    public subscript(position: String) -> T.C? {
        _read {
            yield children[position]
        }
    }
    
    public mutating func getOrInsert(name: String) -> T.C {
        let new = T.C()
        new.parent = target;
        new.name = name;
        return self.children[name, default: new]
    }
}

public struct BoundPairTree<T> where T: BoundPairParent, T.C.P == T {
    public init<C>(data: C) where C: Collection, C.Element == T {
        let asDict: [T.ID: BoundPairTreeRow<T>] = .init(uniqueKeysWithValues:
            data.map { ($0.id, BoundPairTreeRow(target: $0, children: $0.children)) }
        );
        
        self.init(data: asDict)
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
            let new = T();
            new.name = name
            
            self.data[name] = .init(target: new, children: .init());
            return new;
        }
    }
    public mutating func getOrInsert(parent: String, child: String) -> T.C {
        if let target = self.data[parent]?.getOrInsert(name: child) {
            return target
        }
        else {
            let new = T();
            new.name = parent
            
            self.data[parent] = .init(target: new, children: .init());
            return self.data[parent]!.getOrInsert(name: child)
        }
    }
}

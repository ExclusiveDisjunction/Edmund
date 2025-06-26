//
//  CategoryBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/25/25.
//

public protocol CategoryBase : ElementBase, UniqueElement, PairBasis {
    func tryNewName(name: String, unique: UniqueEngine) -> Bool;
    func setNewName(name: String, unique: UniqueEngine);
    
    var isLocked: Bool { get }
}

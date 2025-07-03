//
//  CategoryBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/25/25.
//

public protocol CategoryBase : ElementBase, UniqueElement, PairBasis {
    @MainActor
    func tryNewName(name: String, unique: UniqueEngine) async -> Bool;
    @MainActor
    func setNewName(name: String, unique: UniqueEngine) async;
    
    var isLocked: Bool { get }
}

//
//  NamedPairKind.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData
import SwiftUI

/*
 public enum NamedPairKind : Int, Equatable {
 case account = 0
 case category = 1
 
 public var name: LocalizedStringKey {
 switch self {
 case .account: "Account"
 case .category: "Category"
 }
 }
 public var subName: LocalizedStringKey {
 switch self {
 case .account: "Sub Account"
 case .category: "Sub Category"
 }
 }
 public var addName: LocalizedStringKey {
 switch self {
 case .account: "Add Account"
 case .category: "Add Category"
 }
 }
 public var addSubName: LocalizedStringKey {
 switch self {
 case .account: "Add Sub Account"
 case .category: "Add Sub Category"
 }
 }
 }
 */

public protocol PairBasis : Identifiable, PersistentModel, Hashable, Equatable, EditableElement, InspectableElement {
    var name: String { get set }
}

public protocol BoundPairParent : PairBasis {
    associatedtype C: BoundPair;
    
    init();
    
    var children: [C]? { get set }
}
public protocol BoundPair : PairBasis {
    associatedtype P: BoundPairParent;
    
    init();
    init(parent: P?);
    
    var parent: P? { get set }
}
public extension BoundPair {
    func eqByName(_ rhs: any BoundPair) -> Bool {
        self.parent_name == rhs.parent_name && self.name == rhs.name
    }
    
    var parent_name: String? {
        get { parent?.name }
        set(v) {
            if let parent = self.parent, let value = v {
                parent.name = value
            }
        }
    }
}

public extension Array where Element: BoundPair {
    func findPair(_ parent: String, _ child: String) -> Element? {
        self.first(where: {$0.name == child && $0.parent_name == parent } )
    }
}
public extension Array where Element: BoundPairParent {
    func findPair(_ parent: String, _ child: String) -> Element.C? {
        guard let foundParent = self.first(where: {$0.name == parent } ) else { return nil }
        
        return foundParent.children?.first(where: {$0.name == child } )
    }
}

//
//  NamedPairKind.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData

public enum NamedPairKind : Int, Equatable {
    case account = 0
    case category = 1
    
    public var name: String {
        switch self {
            case .account: "Account"
            case .category: "Category"
        }
    }
    public var pluralized:  String {
        switch self {
        case .account: "Accounts"
        case .category: "Categories"
        }
    }
    public var subName: String {
        "Sub \(self.rawValue)"
    }
    public var subNamePlural: String {
        "Sub \(self.pluralized)"
    }
    
}

public protocol BoundPairParent : Identifiable, PersistentModel {
    associatedtype C: BoundPair;
    
    init();
    
    var name: String { get set }
    var children: [C] { get set }
    static var kind: NamedPairKind { get}
}
public protocol BoundPair : Identifiable, PersistentModel, Hashable, Equatable {
    associatedtype P: BoundPairParent;
    
    init();
    init(parent: P?);
    
    var parent: P? { get set }
    var name: String { get set }
    static var kind: NamedPairKind { get }
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
        
        return foundParent.children.first(where: {$0.name == child } )
    }
}

/*
 struct UnboundNamedPair : NamedPair {
 init(_ parent: String = "", _ child: String = "") {
 self.name = parent;
 self.sub_name = child;
 }
 init(from: any NamedPair) {
 self.name = from.parent_name;
 self.sub_name = from.child_name;
 }
 
 private var name: String;
 private var sub_name: String;
 
 static func ==(lhs: UnboundNamedPair, rhs: UnboundNamedPair) -> Bool{
 lhs.name == rhs.name && rhs.sub_name == rhs.sub_name
 }
 func hash(into hasher: inout Hasher) {
 hasher.combine(name);
 hasher.combine(sub_name);
 }
 
 var id: UUID = UUID();
 var parent_name: String {
 get { name }
 set(v) { name = v }
 }
 var child_name: String {
 get { sub_name }
 set(v) { sub_name = v }
 }
 static var kind: NamedPairKind { .nondetermined }
 
 }
 */

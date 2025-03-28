//
//  NamedPairKind.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData

enum NamedPairKind : String, Equatable {
    case account = "Account"
    case category = "Category"
    case nondetermined = "Non-Determined"
    
    func pluralized() -> String {
        switch self {
        case .account: "Accounts"
        case .category: "Categories"
            case .nondetermined: "Non-Determined Pairs"
        }
    }
    func subName() -> String {
        "Sub \(self.rawValue)"
    }
    func subNamePlural() -> String {
        "Sub \(self.pluralized())"
    }
    
}

protocol BoundPairParent : Identifiable, PersistentModel {
    associatedtype C: BoundPair;
    
    init();
    
    var name: String { get set }
    var children: [C] { get set }
    static var kind: NamedPairKind { get}
}
protocol BoundPair : Identifiable, PersistentModel, Hashable {
    associatedtype P: BoundPairParent;
    
    init();
    
    var parent: P? { get set }
    var name: String { get set }
    static var kind: NamedPairKind { get }
}
extension BoundPair {
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

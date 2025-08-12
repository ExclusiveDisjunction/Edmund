//
//  CategoryTableRow.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import SwiftUI
import SwiftData
import EdmundCore

@Observable
final class CategoryTableRow : Identifiable, Parentable {
    init(subCategory: SubCategory) {
        self.id = UUID();
        self.target = subCategory;
        self.children = nil;
        self.name = subCategory.name;
    }
    init(category: EdmundCore.Category) {
        self.id = UUID();
        self.target = category;
        self.children = category.children.map { Self(subCategory: $0) }
        self.name = category.name;
    }
    
    var target: any CategoryBase
    let id: UUID;
    var name: String;
    var children: [CategoryTableRow]?;
    var isEditing: Bool = false;
    var attempts: CGFloat = 0;
}

@Observable
public class NameEditingRow {
    public init(start: String) {
        self.name = start
    }
    
    public var attempts: CGFloat = 0.0;
    public var name: String;
    
    public func validate() -> Bool {
        let name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !name.isEmpty
    }
}
public extension NameEditingRow {
    @MainActor
    func tryApply<T>(over: T, unique: UniqueEngine) async -> Bool where T: CategoryBase {
        let name = self.name.trimmingCharacters(in: .whitespacesAndNewlines);
        
        if !name.isEmpty {
            if await over.tryNewName(name: name, unique: unique) {
                await over.setNewName(name: name, unique: unique)
                return true;
            }
        }
        
        withAnimation(.default) {
            attempts += 1;
        }
        
        return false
    }
}

public struct SkinnyWrapper<T> : Identifiable {
    public init(_ data: T, id: UUID = UUID()) {
        self.data = data
        self.id = id
    }
    
    public let data: T;
    public let id: UUID;
}

public enum EditingState {
    case view
    case edit(NameEditingRow)
    case adding(NameEditingRow)
    
    public var isEdit: Bool {
        self.snapshot != nil
    }
    public var snapshot: NameEditingRow? {
        switch self {
            case.view: nil
            case .edit(let e): e
            case .adding(let e): e
        }
    }
    
    @MainActor
    public mutating func trySwitchMode<T>(over: T, unique: UniqueEngine, context: ModelContext) async -> Bool where T: CategoryBase, T: PersistentModel {
        switch self {
            case .view:
                self = .edit(NameEditingRow(start: over.name))
                return true
            case .edit(let e):
                guard await e.tryApply(over: over, unique: unique) else {
                    return false;
                }
                
                self = .view
                return true
            case .adding(let e):
                guard await e.tryApply(over: over, unique: unique) else {
                    return false;
                }
                
                context.insert(over)
                self = .view
                return true
        }
    }
}

@Observable
public class SubCategoryWrapper : Identifiable {
    public init(_ over: SubCategory, id: UUID = UUID()) {
        self.over = over
        self.id = id
        self.state = .view
    }
    
    public let over: SubCategory;
    public let id: UUID;
    public var state: EditingState;
}

@Observable
public class CategoryWrapper : Identifiable {
    public init(_ over: EdmundCore.Category, id: UUID = UUID()) {
        self.over = over
        self.id = id
        self.state = .view
        self.children = over.children.map { SubCategoryWrapper($0) }
    }
    
    public let over: EdmundCore.Category;
    public let id: UUID;
    public var state: EditingState;
    public var children: [SubCategoryWrapper];
}

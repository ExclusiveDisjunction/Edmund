//
//  Parents.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/24/25.
//

import SwiftUI
import SwiftData

/// Represents an object that can parent itself in a recursive nature.
public protocol Parentable {
    /// The optional children of the current node. If this is nil, this instance is a "leaf".
    var children: [Self]? { get }
}
public extension Parentable {
    /// Determines if the element has children. If this is `false`, then the node has no children.
    var isLeaf: Bool {
        self.children == nil;
    }
    /// When `true`, the node has the capacity to have children ( the children variable is not `nil`).
    var isParent: Bool {
        self.children != nil;
    }
}

/// A sub class of `InspectionManifest<T>` that allows for the usage of a type thati is `Parentable`.
/// Since `InspectionManifest<T>` expects 'flat' types, using a type that is `Parentable` will not work for that stucture.
/// However, this class will look within the tree structure for the selected elements, and then present them if it is found.
@Observable
public class ParentInspectionManifest<T> : InspectionManifest<T> where T: Parentable, T: Identifiable {
    /// Searches the children of the `of` instance, trying to find something with an id that matches `id`.
    /// - Parameters:
    ///     - of: The root to search from
    ///     - id: The id of which to select out of the tree
    /// - Returns:
    ///     The selected element from this tree, starting at `of`, that matches `id`; if such a node exists.
    private static func searchChildren(_ of: T, id: T.ID) -> T? {
        if of.id == id {
            return of;
        }
        
        if let children = of.children {
            for child in children {
                if let target = Self.searchChildren(child, id: id) {
                    return target;
                }
            }
        }
        
        return nil;
    }
    
    /// Selects the elements out of `on` from `selection`, and if the count is exactly 1, open that element for inspection.
    public override func inspectSelected(_ selection: Set<T.ID>, mode: InspectionMode, on: [T], warning: SelectionWarningManifest) {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        guard let first = selection.first, selection.count == 1 else { warning.warning = .tooMany; return }
        
        for item in on {
            if let target = Self.searchChildren(item, id: first) {
                self.open(target, mode: mode)
                return;
            }
        }
        
        // By this point, nothing was found in the selection
        warning.warning = .noneSelected;
    }
}

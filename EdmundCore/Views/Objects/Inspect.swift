//
//  Inspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

/// A combination signals used to indicate what you want to do with a specific data element.
public enum InspectionMode : Int, Identifiable, CaseIterable {
    /// Signals the data should be edited
    case edit
    /// Signals the data should be viewed/inspected
    case inspect
    /// Singlas the data is being added. This is essentially `Self.edit`, but gives extra context.
    case add
    
    public var id: String {
        switch self {
            case .edit: "edit"
            case .inspect: "view"
            case .add: "add"
        }
    }
    /// The icon used for the specific mode. Note that `Self.add` should not be used in this context.
    public var icon: String {
        switch self {
            case .edit: "pencil"
            case .inspect: "info.circle"
            case .add: "exclimationmark"
        }
    }
    /// The label used to display what action is taking place. Note that `Self.add` should not be used in this context.
    public var display: String {
        switch self {
            case .edit: "Edit"
            case .inspect: "Inspect"
            case .add: "Add"
        }
    }
}

/// A wrapper that allows for streamlined signaling of inspection/editing/adding for a data type.
@Observable
public class InspectionManifest<T> {
    public init() {
        mode = .inspect;
        value = nil;
    }
    /// The current mode being taken by the manifest.
    public var mode: InspectionMode;
    /// The value that is being added/edited/inspected
    public var value: T?
    
    /// If the `selection` contains only one id, and it resolves to a `T` value, it will open it with the specified `mode`. Otherwise, it will omit a warning.
    public func inspectSelected(_ selection: Set<T.ID>, mode: InspectionMode, on: [T], warning: SelectionWarningManifest) where T: Identifiable {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        guard selection.count == 1 else { warning.warning = .tooMany; return }
        
        let objects = on.filter { selection.contains($0.id) }
        guard let target = objects.first else { warning.warning = .noneSelected; return }
        
        self.open(target, mode: mode)
    }
    
    /// Opens a specific element with a specified mode.
    public func open(_ value: T, mode: InspectionMode) {
        self.value = value
        self.mode = mode
    }
}

/// Represents an object that can parent itself in a recursive nature.
public protocol Parentable {
    /// The optional children of the current node. If this is nil, this instance is a "leaf".
    var children: [Self]? { get }
}
public extension Parentable {
    var isLeaf: Bool {
        self.children == nil;
    }
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

/// A general toobar item used to indicate etierh inspection or editing. Do not use this with `InspectionMode.add`, as that is undefined behavior.
public struct GeneralIEToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
    /// Constructs the toolbar button given the specifed context.
    /// - Parameters:
    ///     - on: The targeted data to be edted/inspected
    ///     - selection: Used to pull out the editing/inspection targets when the button is pressed.
    ///     - inspect: The `InspectionManifest<T>` used to signal to the parent view of the user's intent
    ///     - warning: The `WarningManifest`used to singal errors to the parent view.
    ///     - role: The kind of button this should be. This should never be `InspectionMode.add`. It will define what kind of signal this will send to the `InspectionManifest<T>`, and what the label/icon will be.
    ///     - placement: The placement of the toolbar button.
    public init(on: [T], selection: Binding<Set<T.ID>>, inspect: InspectionManifest<T>, warning: SelectionWarningManifest, role: InspectionMode, placement: ToolbarItemPlacement = .automatic) {
        self.on = on;
        self._selection = selection;
        self.inspect = inspect
        self.warning = warning;
        self.role = role;
        self.placement = placement
    }
    
    private let on: [T];
    private let inspect: InspectionManifest<T>;
    private let warning: SelectionWarningManifest;
    private let role: InspectionMode
    private var placement: ToolbarItemPlacement = .automatic
    @Binding private var selection: Set<T.ID>;
    
    @ToolbarContentBuilder
    public var body: some CustomizableToolbarContent {
        ToolbarItem(id: role.id, placement: placement) {
            Button(action: {
                inspect.inspectSelected(selection, mode: role, on: on, warning: warning)
            }) {
                Label(role.display, systemImage: role.icon)
            }
        }
    }
}

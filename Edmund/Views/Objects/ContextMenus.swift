//
//  Warnings.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/1/25.
//

import SwiftUI
import SwiftData

/// A simplified, general view to place inside of a `ContextMenu`. it provides shortcuts to view (if allowed), edit, and delete objects. Optionally, it provides a shortcut for adding objects.
public struct SingularContextMenu<T> : View where T: Identifiable {
    /// The object that the menu is for.
    private var target: T;
    /// A manifest showing the view/edit mode of the selected object.
    private var inspection: InspectionManifest<T>;
    /// The deleting action used to store the information that can be deleted.
    private var delete: DeletingManifest<T>;
    /// Signifies that the context menu allows for view inspection
    private let canInspect: Bool;
    /// An optional function called that signals the add operation.
    private let add: (() -> Void)?;
    /// A label that is shown for the add functionality, if the `add` member exists.
    private let addLabel: LocalizedStringKey;
    /// Signals that the view uses the Slide style.
    private let asSlide: Bool;
    
    /// Constructs a context menu based on the provided information.
    /// - Parameters:
    ///     - target: The element to modify
    ///     - inspect: The `InspectionManifest<T>` used to signal to the parent view that an inspection/edit should take place.
    ///     - remove: The `DeletingManifest<T>` used to signal to the parent view that the element is being removed.
    ///     - addLabel:  A `LocalizedStringKey` used to signal the "Add" option, if allowed.
    ///     - add: A method that will add a new `T` to the data store. If this is `nil`, then adding is disallowed.
    ///     - canInspect: If the `target` can be inspected or not.
    ///     - asSlide: When true, the menu will be presented as a slide menu, with tinted colors.
    public init(_ target: T, inspect: InspectionManifest<T>, remove: DeletingManifest<T>, addLabel: LocalizedStringKey = "Add", add: (() -> Void)? = nil, canInspect: Bool = true, asSlide: Bool = false) {
        self.target = target
        self.inspection = inspect
        self.canInspect = canInspect
        self.delete = remove
        self.add = add
        self.addLabel = addLabel
        self.asSlide = asSlide
    }
    
    public var body: some View {
        if let add = add {
            Button(action: add) {
                Label(addLabel, systemImage: "plus")
            }
        }
        
        if canInspect {
            Button(action: {
                inspection.open(target, mode: .inspect)
            }) {
                Label("Inspect", systemImage: "info.circle")
            }.tint(asSlide ? .green : .clear)
        }
        
        Button(action: {
            inspection.open(target, mode: .edit)
        }) {
            Label("Edit", systemImage: "pencil")
        }.tint(asSlide ? .blue : .clear)
        
        Button(action: {
            delete.action = [target]
        }) {
            Label("Delete", systemImage: "trash").foregroundStyle(.red)
        }.tint(asSlide ? .red : .clear)
    }
}

/// A generalized context menu that runs for `.contextMenu(forSelectionType: T.ID)`.
public struct SelectionContextMenu<T> : View where T: Identifiable {
    /// A handle for viewing/editing
    private let inspect: InspectionManifest<T>;
    /// A handle for deleting objects.
    private let delete: DeletingManifest<T>;
    /// The warning manifest used for alerting about errors.
    private let warning: SelectionWarningManifest;
    /// The selection provided by the context menu.
    private let selection: Set<T.ID>;
    /// When true, the  "Inspect" menu option is provided.
    private let canView: Bool;
    private let data: [T];
    
    /// Constructs a context menu based on the provided information.
    /// - Parameters:
    ///     - sel: The selection being provided.
    ///     - data: The data that the selection comes from.
    ///     - inspect: The `InspectionManifest<T>` used to signal to the parent view that an inspection/edit should take place.
    ///     - delete: The `DeletingManifest<T>` used to signal to the parent view that the element is being removed.
    ///     - warning: The `WarningManifest` used to signal to the parent view that something is wrong.
    ///     - canView: When true, inspection is allowed.
    public init(_ sel: Set<T.ID>, data: [T], inspect: InspectionManifest<T>, delete: DeletingManifest<T>, warning: SelectionWarningManifest, canView: Bool = true) {
        self.selection = sel
        self.data = data
        self.inspect = inspect
        self.delete = delete
        self.warning = warning
        self.canView = canView
    }
    
    private func handleEdit() {
        inspect.inspectSelected(selection, mode: .edit, on: data, warning: warning)
    }
    private func handleView() {
        inspect.inspectSelected(selection, mode: .inspect, on: data, warning: warning)
    }
    private func handleDelete() {
        delete.deleteSelected(selection, on: data, warning: warning)
    }
    
    public var body: some View {
        if selection.count == 1 {
            if canView {
                Button(action: handleView ) {
                    Label("Inspect", systemImage: "info.circle")
                }
            }
            
            Button(action: handleEdit  ) {
                Label("Edit", systemImage: "pencil")
            }
        }
        
        Button(action: handleDelete) {
            Label("Delete", systemImage: "trash").foregroundStyle(.red)
        }
    }
}


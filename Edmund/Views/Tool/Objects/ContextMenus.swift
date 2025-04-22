//
//  Warnings.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/1/25.
//

import SwiftUI
import SwiftData

/// A simplified, general view to place inside of a `ContextMenu`. it provides shortcuts to view (if allowed), edit, and delete objects. Optionally, it provides a shortcut for adding objects.
struct SingularContextMenu<T> : View where T: Identifiable {
    /// The object that the menu is for.
    var target: T;
    /// A manifest showing the view/edit mode of the selected object.
    var inspection: InspectionManifest<T>;
    /// The deleting action used to store the information that can be deleted.
    var delete: DeletingManifest<T>;
    /// Signifies that the context menu allows for view inspection
    let canInspect: Bool;
    /// An optional function called that signals the add operation.
    let add: (() -> Void)?;
    /// A label that is shown for the add functionality, if the `add` member exists.
    let addLabel: LocalizedStringKey;
    /// Signals that the view uses the Slide style.
    let asSlide: Bool;
    
    init(_ target: T, inspect: InspectionManifest<T>, remove: DeletingManifest<T>, addLabel: LocalizedStringKey = "Add", add: (() -> Void)? = nil, canInspect: Bool = true, asSlide: Bool = false) {
        self.target = target
        self.inspection = inspect
        self.canInspect = canInspect
        self.delete = remove
        self.add = add
        self.addLabel = addLabel
        self.asSlide = asSlide
    }
    
    var body: some View {
        if let add = add {
            Button(action: add) {
                Label(addLabel, systemImage: "plus")
            }
        }
        
        if canInspect {
            Button(action: {
                inspection.open(target, mode: .view)
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
struct ManyContextMenu<T> : View where T: Identifiable {
    /// A handle for viewing/editing
    let inspect: InspectionManifest<T>;
    /// A handle for deleting objects.
    let delete: DeletingManifest<T>;
    let warning: WarningManifest;
    /// The selection provided by the context menu.
    let selection: Set<T.ID>;
    /// When true, the  "Inspect" menu option is provided. 
    let canView: Bool;
    let data: [T];
    
    init(_ sel: Set<T.ID>, data: [T], inspect: InspectionManifest<T>, delete: DeletingManifest<T>, warning: WarningManifest, canView: Bool = true) {
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
        inspect.inspectSelected(selection, mode: .view, on: data, warning: warning)
    }
    private func handleDelete() {
        delete.deleteSelected(selection, on: data, warning: warning)
    }
    
    var body: some View {
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


//
//  Delete.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI
import CoreData
import os

/// An observable class that provides deleting confrimation dialog abstraction. It includes a member, `isDeleting`, which can be bound. This value will become `true` when the internal list is not `nil` and not empty.
@Observable
public class DeletingManifest<T> where T: Identifiable {
    public init() { }
    
    /// The objects to delete.
    public final var action: [T]?;
    /// A bindable value that returns true when the `action` is not `nil` and the list is not empty.
    public final var isDeleting: Bool {
        get {
            guard let action = action else { return false }
            
            return !action.isEmpty
        }
        set {
            if self.isDeleting == newValue {
                return
            }
            else {
                if newValue {
#if DEBUG
                    print("warning: isDeleting set to true")
#endif
                    
                    action = []
                }
                else {
                    action = nil
                }
            }
        }
    }
    
    /// Removes all elements in `on` that are in `selection`, showing a warning if a failure occurs.
    public final func deleteSelected(_ selection: Set<T.ID>, on: [T], warning: SelectionWarningManifest) where T: Identifiable {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        
        let targets = on.filter { selection.contains($0.id) }
        guard !targets.isEmpty else { warning.warning = .noneSelected; return }
        
        self.action = targets
    }
    /// Removes one element from `on` that matches the id `selection`, showing a warning if a failure occurs.
    public final func deleteSelected(_ selection: T.ID, on: [T], warning: SelectionWarningManifest) where T: Identifiable {
        deleteSelected([selection], on: on, warning: warning)
    }
}

/// An abstraction to show in the `.confirmationDialog` of a view. This will handle the deleting of the data inside of a `DeletingManifest<T>`.
public struct DeletingActionConfirm<T>: View where T: NSManagedObject & Identifiable {
    /// The data that can be deleted.
    private var deleting: DeletingManifest<T>;
    /// Runs after the deleting occurs.
    private let postAction: (() -> Void)?;
    
    /// Constructs the view around the specified data
    /// - Parameters:
    ///     - deleting: The `DeletingManifest<T>` source of truth..
    ///     - post: An action to run after the removal occurs. If the user cancels, this will not be run.
    public init(_ deleting: DeletingManifest<T>, post: (() -> Void)? = nil) {
        self.deleting = deleting
        self.postAction = post
    }
    
    @Environment(\.managedObjectContext) private var objectContext;
    @Environment(\.loggerSystem) private var loggerSystem;
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        if let deleting = deleting.action {
            Button("Delete") {
                loggerSystem?.data.debug("Performing delete on \(deleting.count) objects without uniqueness constraints.")
                for data in deleting {
                    objectContext.delete(data);
                }
                
                do {
                    try objectContext.save();
                }
                catch let e {
                    loggerSystem?.data.error("Unable to save: \(e.localizedDescription, privacy: .public)");
                    dismiss();
                    
                    return;
                }
                
                self.deleting.isDeleting  = false
                if let post = postAction {
                    post()
                }
            }
        }
        
        Button("Cancel", role: .cancel) {
            deleting.isDeleting = false
        }
    }
}

/// A toolbar button that can be used to signal the deleting of objects over a `DeletingManifest<T>` and `WarningManifest`.
public struct GeneralDeleteToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
    /// Constructs the toolbar with the needed abstraction information.
    /// - Parameters:
    ///     - on: The source of truth list of data that can be deleted.
    ///     - selection: A binding to the selection that can take place in the view. When the delete action is triggered, it will pull from this selection, and `on` to get all elements.
    ///     - delete: The `DeletingManifest<T>` used to signal the intent to remove elements.
    ///     - warning: The warning manifest used to signal mistakes.
    ///     - placement: A customization of where the delete button should go.
    public init(on: [T], selection: Binding<Set<T.ID>>, delete: DeletingManifest<T>, warning: SelectionWarningManifest, placement: ToolbarItemPlacement = .automatic) {
        self.on = on;
        self._selection = selection;
        self.delete = delete
        self.warning = warning
        self.placement = placement
    }
    
    private let on: [T];
    private let delete: DeletingManifest<T>;
    private let warning: SelectionWarningManifest;
    private let placement: ToolbarItemPlacement;
    @Binding private var selection: Set<T.ID>;
    
    @ToolbarContentBuilder
    public var body: some CustomizableToolbarContent {
        ToolbarItem(id: "delete", placement: placement) {
            Button(action: {
                delete.deleteSelected(selection, on: on, warning: warning)
            }) {
                Label("Delete", systemImage: "trash").foregroundStyle(.red)
            }
        }
    }
}

public struct DeleteConfirmModifier<T> : ViewModifier where T: Identifiable & NSManagedObject {
    public init(manifest: DeletingManifest<T>, post: (() -> Void)? = nil) {
        self.manifest = manifest;
    }
    
    @Bindable private var manifest: DeletingManifest<T>;
    private let post: (() -> Void)?;
    
    public func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "deleteItemsConfirm",
                isPresented: $manifest.isDeleting,
                titleVisibility: .visible
            ) {
                DeletingActionConfirm(manifest, post: post)
            }
    }
}

extension View {
    public func withDeleting<T>(manifest: DeletingManifest<T>, post: (() -> Void)? = nil) -> some View
    where T: Identifiable & NSManagedObject {
        self.modifier(DeleteConfirmModifier<T>(manifest: manifest, post: post))
    }
}

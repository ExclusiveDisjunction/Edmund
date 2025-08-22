//
//  Delete.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI
import SwiftData
import EdmundCore

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
/// This is different from `DeletingActionConfirm<T>` because this view requires the deleting action to be provided.
/// Use this when `T` is a wrapper over an `any V`, where all inheriters of `V` are `PersistentModel`.
public struct AbstractDeletingActionConfirm<T> : View where T: Identifiable {
    /// Constructs the view around the data provided.
    /// - Parameters:
    ///     - deleting: The `DeletingManifest<T>` source of truth.
    ///     - delete: The function that will remove the value `T` from the current `ModelContext`. If the `deleting` has more than one element, one call will be made per object.
    ///     - post: An action to run after all elements have ben deleted. If nothing is deleted, this will not be called.
    public init(_ deleting: DeletingManifest<T>, delete: @escaping (T, ModelContext) -> Void, post: (() -> Void)? = nil) {
        self.deleting = deleting
        self.delete = delete
        self.postAction = post
    }
    
    private var deleting: DeletingManifest<T>;
    private let delete: (T, ModelContext) -> Void;
    private let postAction: (() -> Void)?;
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.loggerSystem) private var loggerSystem;
    
    @ViewBuilder
    private var cancelButton: some View {
        Button("Cancel", role: .cancel) {
            deleting.isDeleting = false
        }
    }
    
    public var body: some View {
        if let deleting = deleting.action {
            Button("Delete") {
                loggerSystem?.data.debug("Performing delete on \(deleting.count) objects without uniqueness constraints.")
                for data in deleting {
                    delete(data, self.modelContext)
                }
                
                self.deleting.isDeleting  = false
                if let post = postAction {
                    post()
                }
            }
        }
        
        cancelButton
    }
}
extension AbstractDeletingActionConfirm where T: UniqueElement, T.ID: Sendable {
    @ViewBuilder
    public var body: some View {
        if let deleting = deleting.action {
            Button("Delete") {
                loggerSystem?.data.debug("Performing delete on \(deleting.count) objects with uniqueness constraints.")
                for data in deleting {
                    let id = data.id;
                    Task {
                        await uniqueEngine.releaseId(key: T.objId, id: id)
                    }
                    delete(data, self.modelContext)
                }
                
                self.deleting.isDeleting  = false
                if let post = postAction {
                    post()
                }
            }
        }
        
        cancelButton
    }
}

/// An abstraction to show in the `.confirmationDialog` of a view. This will handle the deleting of the data inside of a `DeletingManifest<T>`.
public struct DeletingActionConfirm<T>: View where T: PersistentModel{
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
    
    public var body: some View {
        AbstractDeletingActionConfirm(deleting, delete: { model, context in
            context.delete(model)
        }, post: postAction)
    }
}
public struct UniqueDeletingActionConfirm<T> : View where T: PersistentModel, T: UniqueElement {
    private var deleting: DeletingManifest<T>;
    private let postAction: (() -> Void)?;
    
    public init(_ deleting: DeletingManifest<T>, post: (() -> Void)? = nil) {
        self.deleting = deleting
        self.postAction = post
    }
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    public var body: some View {
        AbstractDeletingActionConfirm(self.deleting, delete: { model, context in
            context.delete(model)
            Task {
                await uniqueEngine.releaseId(key: T.objId, id: model.uID)
            }
        }, post: postAction)
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

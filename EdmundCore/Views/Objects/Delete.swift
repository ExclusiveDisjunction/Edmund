//
//  Delete.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI
import SwiftData

/// An observable class that provides deleting confrimation dialog abstraction. It includes a member, `isDeleting`, which can be bound. This value will become `true` when the internal list is not `nil` and not empty.
@Observable
public class DeletingManifest<T> where T: Identifiable {
    public init() {
        
    }
    /// The objects to delete.
    public var action: [T]?;
    /// A bindable value that returns true when the `action` is not `nil` and the list is not empty.
    public var isDeleting: Bool {
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
    
    public func deleteSelected(_ selection: Set<T.ID>, on: [T], warning: WarningManifest) where T: Identifiable {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        
        let targets = on.filter { selection.contains($0.id) }
        guard !targets.isEmpty else { warning.warning = .noneSelected; return }
        
        self.action = targets
    }
    public func deleteSelected(_ selection: T.ID, on: [T], warning: WarningManifest) where T: Identifiable {
        deleteSelected([selection], on: on, warning: warning)
    }
}

public struct AbstractDeletingActionConfirm<T> : View where T: Identifiable {
    private var deleting: DeletingManifest<T>;
    private let delete: (T, ModelContext) -> Void;
    private let postAction: (() -> Void)?;
    @Environment(\.modelContext) private var modelContext;
    
    public init(_ deleting: DeletingManifest<T>, delete: @escaping (T, ModelContext) -> Void, post: (() -> Void)? = nil) {
        self.deleting = deleting
        self.delete = delete
        self.postAction = post
    }
    
    public var body: some View {
        if let deleting = deleting.action {
            Button("Delete") {
                for data in deleting {
                    delete(data, self.modelContext)
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

/// An abstraction to show in the `.confirmationDialog` of a view. This will handle the deleting of the data inside of a `DeletingManifest<T>`.
public struct DeletingActionConfirm<T>: View where T: PersistentModel{
    /// The data that can be deleted.
    private var deleting: DeletingManifest<T>;
    /// Runs after the deleting occurs.
    private let postAction: (() -> Void)?;
    
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

public struct GeneralDeleteToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
    public init(on: [T], selection: Binding<Set<T.ID>>, delete: DeletingManifest<T>, warning: WarningManifest, placement: ToolbarItemPlacement = .automatic) {
        self.on = on;
        self._selection = selection;
        self.delete = delete
        self.warning = warning
        self.placement = placement
    }
    
    private let on: [T];
    private let delete: DeletingManifest<T>;
    private let warning: WarningManifest;
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

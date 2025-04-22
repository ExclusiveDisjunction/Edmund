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
class DeletingManifest<T> where T: Identifiable {
    /// The objects to delete.
    var action: [T]?;
    /// A bindable value that returns true when the `action` is not `nil` and the list is not empty.
    var isDeleting: Bool {
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
    
    func deleteSelected(_ selection: Set<T.ID>, on: [T], warning: WarningManifest) where T: Identifiable {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        
        let targets = on.filter { selection.contains($0.id) }
        guard !targets.isEmpty else { warning.warning = .noneSelected; return }
        
        self.action = targets
    }
    func deleteSelected(_ selection: T.ID, on: [T], warning: WarningManifest) where T: Identifiable {
        deleteSelected([selection], on: on, warning: warning)
    }
}

struct AbstractDeletingActionConfirm<T> : View where T: Identifiable {
    var deleting: DeletingManifest<T>;
    let delete: (T, ModelContext) -> Void;
    let postAction: (() -> Void)?;
    @Environment(\.modelContext) private var modelContext;
    
    init(_ deleting: DeletingManifest<T>, delete: @escaping (T, ModelContext) -> Void, post: (() -> Void)? = nil) {
        self.deleting = deleting
        self.delete = delete
        self.postAction = post
    }
    
    var body: some View {
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
struct DeletingActionConfirm<T>: View where T: PersistentModel{
    /// The data that can be deleted.
    var deleting: DeletingManifest<T>;
    /// Runs after the deleting occurs.
    let postAction: (() -> Void)?;
    
    init(_ deleting: DeletingManifest<T>, post: (() -> Void)? = nil) {
        self.deleting = deleting
        self.postAction = post
    }
    
    var body: some View {
        AbstractDeletingActionConfirm(deleting, delete: { model, context in
            context.delete(model)
        }, post: postAction)
    }
}

struct GeneralDeleteToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
    let on: [T];
    @Binding var selection: Set<T.ID>;
    let delete: DeletingManifest<T>;
    let warning: WarningManifest;
    var placement: ToolbarItemPlacement = .automatic
    
    @ToolbarContentBuilder
    var body: some CustomizableToolbarContent {
        ToolbarItem(id: "delete", placement: placement) {
            Button(action: {
                delete.deleteSelected(selection, on: on, warning: warning)
            }) {
                Label("Delete", systemImage: "trash").foregroundStyle(.red)
            }
        }
    }
}

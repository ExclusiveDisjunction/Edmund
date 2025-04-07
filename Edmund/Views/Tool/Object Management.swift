//
//  Warnings.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/1/25.
//

import SwiftUI
import SwiftData

/// The warning message to be presented.
enum WarningKind: Int, Identifiable {
    
    /// The warning that no elements are selected, when at least one was expected.
    case noneSelected = 0
    /// The warning that too many elements are selected, as only one was expected.
    case tooMany = 1
    
    var id: Self { self }
    /// Returns the `LocalizedStringKey` that
    var message: LocalizedStringKey {
        switch self {
            case .noneSelected: "noItems"
            case .tooMany: "tooManyItems"
        }
    }
}

struct WarningMessage: Identifiable {
    let message: LocalizedStringKey
    let title: LocalizedStringKey
    
    var id: UUID { UUID() }
}

/// An observable class that provides warning funcntionality. It includes a memeber, `isPresented`, which can be bound. This value will become `true` when the internal `warning` is not `nil`.
@Observable
class BaseWarningManifest<T> {
    var warning: T?;
    var isPresented: Bool {
        get { warning != nil }
        set {
            if self.isPresented == newValue { return }
            
            warning = nil
        }
    }
}

typealias WarningManifest = BaseWarningManifest<WarningKind>;
typealias StringWarningManifest = BaseWarningManifest<WarningMessage>

enum InspectionMode {
    case edit, view
}

@Observable
class InspectionManifest<T> where T: Identifiable {
    var mode: InspectionMode = .view
    var value: T?
    
    func inspectSelected(_ selection: Set<T.ID>, mode: InspectionMode, on: [T], warning: WarningManifest) where T: Identifiable {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        guard selection.count == 1 else { warning.warning = .tooMany; return }
        
        let objects = on.filter { selection.contains($0.id) }
        guard let target = objects.first else { warning.warning = .noneSelected; return }
        
        self.open(target, mode: mode)
    }
    
    func open(_ value: T, mode: InspectionMode) {
        self.value = value
        self.mode = mode
    }
}

/// An observable class that provides deleting confrimation dialog abstraction. It includes a member, `isDeleting`, which can be bound. This value will become `true` when the internal list is not `nil` and not empty.
@Observable
class DeletingManifest<T> where T: PersistentModel {
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
    
    @Environment(\.modelContext) private var modelContext;
    
    var body: some View {
        if let deleting = deleting.action {
            Button("Delete") {
                for data in deleting {
                    modelContext.delete(data)
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

/// A simplified, general view to place inside of a `ContextMenu`. it provides shortcuts to view (if allowed), edit, and delete objects. Optionally, it provides a shortcut for adding objects.
struct GeneralContextMenu<T> : View where T: Identifiable, T: PersistentModel {
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
struct SelectionsContextMenu<T> : View where T: Identifiable, T: PersistentModel {
    /// A handle for viewing/editing
    let inspect: InspectionManifest<T>;
    /// A handle for deleting objects.
    let delete: DeletingManifest<T>;
    let warning: WarningManifest;
    /// The selection provided by the context menu.
    let selection: Set<T.ID>;
    /// When true, the  "Inspect" menu option is provided. 
    let canView: Bool;
    
    @Query private var data: [T];
    
    init(_ sel: Set<T.ID>, inspect: InspectionManifest<T>, delete: DeletingManifest<T>, warning: WarningManifest, canView: Bool = true) {
        self.selection = sel
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

struct GeneralInspectToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
    let on: [T];
    @Binding var selection: Set<T.ID>;
    let inspect: InspectionManifest<T>;
    let warning: WarningManifest;
    let role: InspectionMode
    var placement: ToolbarItemPlacement = .automatic
    
    @ToolbarContentBuilder
    var body: some CustomizableToolbarContent {
        ToolbarItem(id: role == .edit ? "edit" : "inspect", placement: placement) {
            Button(action: {
                inspect.inspectSelected(selection, mode: role, on: on, warning: warning)
            }) {
                Label(role == .edit ? "Edit" : "Inspect", systemImage: role == .edit ? "pencil" : "info.circle")
            }
        }
    }
}
struct GeneralDeleteToolbarButton<T> : CustomizableToolbarContent where T: PersistentModel, T: Identifiable {
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

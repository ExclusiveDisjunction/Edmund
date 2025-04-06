//
//  Warnings.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/1/25.
//

import SwiftUI
import SwiftData

enum WarningKind: Int, Identifiable {
    case noneSelected = 0, tooMany = 1
    
    var id: Self { self }
    var message: LocalizedStringKey {
        switch self {
            case .noneSelected: "noItems"
            case .tooMany: "tooManyItems"
        }
    }
}
@Observable
class WarningManifest {
    var warning: WarningKind?;
    var isPresented: Bool {
        get { warning != nil }
        set {
            if self.isPresented == newValue { return }
            
            if newValue {
                warning = .noneSelected
            }
            else {
                warning = nil
            }
        }
    }
}

@Observable
class DeletingManifest<T> where T: PersistentModel {
    var action: [T]?;
    var isDeleting: Bool {
        get { action != nil }
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
}

struct DeletingActionConfirm<T>: View where T: PersistentModel {
    var deleting: DeletingManifest<T>;
    let postAction: (() -> Void)? = nil;
    
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

struct SelectionsContextMenu<T> : View where T: Identifiable, T: PersistentModel {
    var inspect: InspectionManifest<T>;
    var delete: DeletingManifest<T>;
    let selection: Set<T.ID>;
    let canView: Bool;
    
    @Query private var data: [T];
    
    init(_ sel: Set<T.ID>, inspect: InspectionManifest<T>, delete: DeletingManifest<T>, canView: Bool = true) {
        self.selection = sel
        self.inspect = inspect
        self.delete = delete
        self.canView = canView
    }
    
    private func handleEdit() {
        guard let id = selection.first, let target = data.first(where: { $0.id == id }) else { return }
        
        inspect.open(target, mode: .edit)
    }
    private func handleView() {
        guard canView else { return }
        guard let id = selection.first, let target = data.first(where: { $0.id == id }) else { return }
        
        inspect.open(target, mode: .view)
    }
    private func handleDelete() {
        let resolved = data.filter { selection.contains( $0.id ) };
        if !resolved.isEmpty {
            delete.action = resolved
        }
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

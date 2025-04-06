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

struct DeletingAction<T>{
    let data: [T];
}

struct DeletingActionConfirm<T>: View where T: PersistentModel {
    @Binding var isPresented: Bool;
    @Binding var action: DeletingAction<T>?;
    let postAction: (() -> Void)? = nil;
    
    @Environment(\.modelContext) private var modelContext;
    
    var body: some View {
        if let deleting = action {
            Button("Delete") {
                for data in deleting.data {
                    modelContext.delete(data)
                }
                
                self.action = nil
                isPresented = false
                if let post = postAction {
                    post()
                }
            }
        }
        
        Button("Cancel", role: .cancel) {
            self.action = nil
            isPresented = false
        }
    }
}


struct GeneralContextMenu<T> : View where T: Identifiable {
    var target: T;
    @Binding var inspection: InspectionManifest<T>?;
    @Binding var delete: DeletingAction<T>?;
    @Binding var isDeleting: Bool;
    let canInspect: Bool;
    let add: (() -> Void)?;
    let addLabel: LocalizedStringKey;
    
    init(_ target: T, inspect: Binding<InspectionManifest<T>?>, remove: Binding<DeletingAction<T>?>, isDeleting: Binding<Bool>, addLabel: LocalizedStringKey = "Add", add: (() -> Void)? = nil, canInspect: Bool = true) {
        self.target = target
        self._inspection = inspect
        self.canInspect = canInspect
        self._delete = remove
        self._isDeleting = isDeleting
        self.add = add
        self.addLabel = addLabel
    }
    
    var body: some View {
        if let add = add {
            Button(action: add) {
                Label(addLabel, systemImage: "plus")
            }
        }
        
        if canInspect {
            Button(action: {
                inspection = .init(mode: .view, value: target)
            }) {
                Label("Inspect", systemImage: "info.circle")
            }
        }
        
        Button(action: {
            inspection = .init(mode: .edit, value: target)
        }) {
            Label("Edit", systemImage: "pencil")
        }
        
        Button(action: {
            delete = .init(data: [target])
            isDeleting = true
        }) {
            Label("Delete", systemImage: "trash").foregroundStyle(.red)
        }
    }
}

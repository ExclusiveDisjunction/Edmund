//
//  Warnings.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/1/25.
//

import SwiftUI
import SwiftData

enum WarningKind {
    case noneSelected, editMultipleSelected
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


struct GeneralContextMenu<T> : View where T: Identifiable{
    var target: T;
    @Binding var inspection: InspectionManifest<T>?;
    let canInspect: Bool;
    let remove: (T) -> Void;
    let add: (() -> Void)?;
    let addLabel: LocalizedStringKey;
    
    init(_ target: T, inspect: Binding<InspectionManifest<T>?>, remove: @escaping (T) -> Void, addLabel: LocalizedStringKey = "Add", add: (() -> Void)? = nil, canInspect: Bool = true) {
        self.target = target
        self._inspection = inspect
        self.canInspect = canInspect
        self.remove = remove
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
            remove(target)
        }) {
            Label("Delete", systemImage: "trash").foregroundStyle(.red)
        }
    }
}

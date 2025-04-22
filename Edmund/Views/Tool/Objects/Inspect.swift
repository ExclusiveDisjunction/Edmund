//
//  Inspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

enum InspectionMode {
    case edit, view
}

@Observable
class InspectionManifest<T> {
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

struct GeneralIEToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
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

//
//  Inspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

public enum InspectionMode {
    case edit, view
}

@Observable
public class InspectionManifest<T> {
    public init() {
        mode = .view;
        value = nil;
    }
    public var mode: InspectionMode;
    public var value: T?
    
    public func inspectSelected(_ selection: Set<T.ID>, mode: InspectionMode, on: [T], warning: WarningManifest) where T: Identifiable {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        guard selection.count == 1 else { warning.warning = .tooMany; return }
        
        let objects = on.filter { selection.contains($0.id) }
        guard let target = objects.first else { warning.warning = .noneSelected; return }
        
        self.open(target, mode: mode)
    }
    
    public func open(_ value: T, mode: InspectionMode) {
        self.value = value
        self.mode = mode
    }
}

public struct GeneralIEToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
    public init(on: [T], selection: Binding<Set<T.ID>>, inspect: InspectionManifest<T>, warning: WarningManifest, role: InspectionMode, placement: ToolbarItemPlacement = .automatic) {
        self.on = on;
        self._selection = selection;
        self.inspect = inspect
        self.warning = warning;
        self.role = role;
        self.placement = placement
    }
    
    private let on: [T];
    private let inspect: InspectionManifest<T>;
    private let warning: WarningManifest;
    private let role: InspectionMode
    private var placement: ToolbarItemPlacement = .automatic
    @Binding private var selection: Set<T.ID>;
    
    @ToolbarContentBuilder
    public var body: some CustomizableToolbarContent {
        ToolbarItem(id: role == .edit ? "edit" : "inspect", placement: placement) {
            Button(action: {
                inspect.inspectSelected(selection, mode: role, on: on, warning: warning)
            }) {
                Label(role == .edit ? "Edit" : "Inspect", systemImage: role == .edit ? "pencil" : "info.circle")
            }
        }
    }
}

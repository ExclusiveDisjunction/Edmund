//
//  Inspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

/// A combination signals used to indicate what you want to do with a specific data element.
public enum InspectionMode : Int, Identifiable, CaseIterable {
    /// Signals the data should be edited
    case edit
    /// Signals the data should be viewed/inspected
    case view
    /// Singlas the data is being added. This is essentially `Self.edit`, but gives extra context.
    case add
    
    public var id: String {
        switch self {
            case .edit: "edit"
            case .view: "view"
            case .add: "add"
        }
    }
    /// The icon used for the specific mode. Note that `Self.add` should not be used in this context.
    public var icon: String {
        switch self {
            case .edit: "pencil"
            case .view: "info.circle"
            case .add: "exclimationmark"
        }
    }
    /// The label used to display what action is taking place. Note that `Self.add` should not be used in this context.
    public var display: String {
        switch self {
            case .edit: "Edit"
            case .view: "Inspect"
            case .add: "Add"
        }
    }
}

/// A wrapper that allows for streamlined signaling of inspection/editing/adding for a data type.
@Observable
public class InspectionManifest<T> {
    public init() {
        mode = .view;
        value = nil;
    }
    /// The current mode being taken by the manifest.
    public var mode: InspectionMode;
    /// The value that is being added/edited/inspected
    public var value: T?
    
    /// If the `selection` contains only one id, and it resolves to a `T` value, it will open it with the specified `mode`. Otherwise, it will omit a warning.
    public func inspectSelected(_ selection: Set<T.ID>, mode: InspectionMode, on: [T], warning: WarningManifest) where T: Identifiable {
        guard !selection.isEmpty else { warning.warning = .noneSelected; return }
        guard selection.count == 1 else { warning.warning = .tooMany; return }
        
        let objects = on.filter { selection.contains($0.id) }
        guard let target = objects.first else { warning.warning = .noneSelected; return }
        
        self.open(target, mode: mode)
    }
    
    /// Opens a specific element with a specified mode.
    public func open(_ value: T, mode: InspectionMode) {
        self.value = value
        self.mode = mode
    }
}

/// A general toobar item used to indicate etierh inspection or editing. Do not use this with `InspectionMode.add`, as that is undefined behavior.
public struct GeneralIEToolbarButton<T> : CustomizableToolbarContent where T: Identifiable {
    /// Constructs the toolbar button given the specifed context.
    /// - Parameters:
    ///     - on: The targeted data to be edted/inspected
    ///     - selection: Used to pull out the editing/inspection targets when the button is pressed.
    ///     - inspect: The `InspectionManifest<T>` used to signal to the parent view of the user's intent
    ///     - warning: The `WarningManifest`used to singal errors to the parent view.
    ///     - role: The kind of button this should be. This should never be `InspectionMode.add`. It will define what kind of signal this will send to the `InspectionManifest<T>`, and what the label/icon will be.
    ///     - placement: The placement of the toolbar button.
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
        ToolbarItem(id: role.id, placement: placement) {
            Button(action: {
                inspect.inspectSelected(selection, mode: role, on: on, warning: warning)
            }) {
                Label(role.display, systemImage: role.icon)
            }
        }
    }
}

//
//  Inspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

/// A combination signals used to indicate what you want to do with a specific data element.
public enum InspectionMode : Int, Identifiable, CaseIterable, Sendable {
    /// Signals the data should be edited
    case edit
    /// Signals the data should be viewed/inspected
    case inspect
    /// Singlas the data is being added. This is essentially `Self.edit`, but gives extra context.
    case add
    case none
    
    public var id: String {
        switch self {
            case .edit: "edit"
            case .inspect: "view"
            case .add: "add"
            case .none:" none"
        }
    }
    /// The icon used for the specific mode. Note that `Self.add` should not be used in this context.
    public var icon: String {
        switch self {
            case .edit: "pencil"
            case .inspect: "info.circle"
            case .add: "exclimationmark"
            case .none: ""
        }
    }
    /// The label used to display what action is taking place. Note that `Self.add` should not be used in this context.
    public var display: String {
        switch self {
            case .edit: "Edit"
            case .inspect: "Inspect"
            case .add: "Add"
            case .none: "internalError"
        }
    }
}

/// A wrapper that allows for streamlined signaling of inspection/editing/adding for a data type.
@Observable
public class InspectionManifest<T> {
    public init() {
        mode = .none;
        value = nil;
    }
    /// The current mode being taken by the manifest.
    public var mode: InspectionMode;
    /// The value that is being added/edited/inspected
    public var value: T?
    
    public var isEditing: Bool {
        get {
            mode == .add || (self.value != nil && mode == .edit)
        }
        set {
            self.value = nil;
            self.mode = .none;
        }
    }
    public var isInspecting: Bool {
        get {
            self.value != nil && mode == .inspect
        }
        set {
            self.value = nil;
            self.mode = .none;
        }
    }
    public var isActive: Bool {
        get {
            self.value != nil || self.mode == .add
        }
        set {
            self.mode = .none;
            self.value = nil;
        }
    }
    
    /// If the `selection` contains only one id, and it resolves to a `T` value, it will open it with the specified `mode`. Otherwise, it will omit a warning.
    public func inspectSelected(_ selection: Set<T.ID>, mode: InspectionMode, on: [T], warning: SelectionWarningManifest) where T: Identifiable {
        let objects = on.filter { selection.contains($0.id) }
        
        guard !objects.isEmpty else { warning.warning = .noneSelected; return }
        guard objects.count == 1 else { warning.warning = .tooMany; return }
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
    public init(on: [T], selection: Binding<Set<T.ID>>, inspect: InspectionManifest<T>, warning: SelectionWarningManifest, role: InspectionMode, placement: ToolbarItemPlacement = .automatic) {
        self.on = on;
        self._selection = selection;
        self.inspect = inspect
        self.warning = warning;
        self.role = role;
        self.placement = placement
    }
    
    private let on: [T];
    private let inspect: InspectionManifest<T>;
    private let warning: SelectionWarningManifest;
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

public struct WithInspectorModifier<T> : ViewModifier where T: Identifiable & NSManagedObject & InspectableElement & TypeTitled {
    public init(manifest: InspectionManifest<T>) {
        self.manifest = manifest
    }
    
    @Bindable private var manifest: InspectionManifest<T>;
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $manifest.isInspecting) {
                manifest.mode = .none
            } content: {
                ElementInspector(data: manifest.value!)
            }
    }
}
public struct WithEditorModifier<T> : ViewModifier where T: Identifiable & NSManagedObject & EditableElement & TypeTitled {
    public init(manifest: InspectionManifest<T>, using: NSPersistentContainer = DataStack.shared.currentContainer, filling: @MainActor @escaping (T) -> Void, post: (() -> Void)? = nil) {
        self.manifest = manifest
        self.using = using
        self.post = post;
        self.filling = filling;
    }
    
    @Bindable private var manifest: InspectionManifest<T>;
    private let using: NSPersistentContainer;
    private let post: (() -> Void)?;
    private let filling: @MainActor (T) -> Void;
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $manifest.isEditing) {
                manifest.mode = .none
            } content: {
                switch manifest.mode {
                    case .add: ElementEditor(using: self.using, filling: filling, postAction: post)
                    case .edit: ElementEditor(using: self.using, from: self.manifest.value!, postAction: post)
                    default: Text("internalError")
                }
            }
    }
}
public struct WithInspectorEditorModifier<T> : ViewModifier where T: Identifiable & NSManagedObject & InspectableElement & EditableElement & TypeTitled {
    public init(manifest: InspectionManifest<T>, using: NSPersistentContainer = DataStack.shared.currentContainer, filling: @MainActor @escaping (T) -> Void, post: (() -> Void)? = nil) {
        
    }
    
    @Bindable private var manifest: InspectionManifest<T>;
    private let using: NSPersistentContainer;
    private let post: (() -> Void)?;
    private let filling: @MainActor (T) -> Void;
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $manifest.isActive) {
                manifest.mode = .none
            } content: {
                switch manifest.mode {
                    case .add: ElementIE(addingTo: using, filling: filling, postAction: post)
                    case .edit: ElementIE(editingFrom: using, editing: manifest.value!, postAction: post)
                    case .inspect: ElementIE(viewingFrom: using, viewing: manifest.value!, postAction: post)
                    default: Text("internalError")
                }
            }
    }
}

public extension View {
    func withInspector<T>(
        manifest: InspectionManifest<T>
    ) -> some View
    where T: InspectableElement & TypeTitled & Identifiable & NSManagedObject {
        self.modifier(WithInspectorModifier(manifest: manifest))
    }
    
    func withEditor<T>(
        manifest: InspectionManifest<T>,
        using: NSPersistentContainer = DataStack.shared.currentContainer,
        filling: @MainActor @escaping (T) -> Void,
        post: (() -> Void)? = nil
    ) -> some View
    where T: EditableElement & TypeTitled & Identifiable & NSManagedObject {
        self.modifier(WithEditorModifier(manifest: manifest, using: using, filling: filling, post: post))
    }
    
    func withInspectorEditor<T>(
        manifest: InspectionManifest<T>,
        using: NSPersistentContainer = DataStack.shared.currentContainer,
        filling: @MainActor @escaping (T) -> Void,
        post: (() -> Void)? = nil
    ) -> some View
    where T: EditableElement & InspectableElement & TypeTitled & Identifiable & NSManagedObject {
        self.modifier(WithInspectorEditorModifier(manifest: manifest, using: using, filling: filling, post: post))
    }
}

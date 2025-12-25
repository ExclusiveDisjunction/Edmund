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
    
    /// Determines if the manifest is in the edit (which includes adding) mode.
    /// This requires that *eitherr* ``mode`` is `.add` *or* ``mode`` is `.edit` and ``value`` is not `nil`.
    public var isEditing: Bool {
        get {
            mode == .add || (self.value != nil && mode == .edit)
        }
        set {
            self.value = nil;
            self.mode = .none;
        }
    }
    /// Determines if the manifest is in inspection mode.
    /// This requires that ``value`` is not `nil`, and ``mode`` is `.inspect`.
    public var isInspecting: Bool {
        get {
            self.value != nil && mode == .inspect
        }
        set {
            self.value = nil;
            self.mode = .none;
        }
    }
    /// Determines if the manifest is in edit, add, or inspect mode.
    public var isActive: Bool {
        get {
            self.value != nil || self.mode == .add
        }
        set {
            self.mode = .none;
            self.value = nil;
        }
    }
    
    public func open<W>(selection: W, editing: Bool, warning: SelectionWarningManifest) where T: Identifiable, W: SelectionContextProtocol, W.Element == T {
        let objects = selection.selectedItems
        
        guard !objects.isEmpty else { warning.warning = .noneSelected; return }
        guard objects.count == 1 else { warning.warning = .tooMany; return }
        guard let target = objects.first else { warning.warning = .noneSelected; return }
        
        self.open(value: target, editing: editing)
    }
    public func open(value: T, editing: Bool) {
        self.value = value;
        self.mode = editing ? .edit : .inspect;
    }
    public func openAdding() {
        self.value = nil;
        self.mode = .add;
    }
}

fileprivate struct InspectionManifestToolbarButton<W> : CustomizableToolbarContent where W: SelectionContextProtocol {
    public init(
        context: W,
        inspect: InspectionManifest<W.Element>,
        warning: SelectionWarningManifest,
        isEdit: Bool,
        placement: ToolbarItemPlacement
    ) {
        self.context = context;
        self.inspect = inspect;
        self.warning = warning;
        self.placement = placement
        self.isEdit = isEdit
    }
    
    private let context: W;
    private let inspect: InspectionManifest<W.Element>;
    private let warning: SelectionWarningManifest;
    private let isEdit: Bool;
    private let placement: ToolbarItemPlacement;
    
    @ToolbarContentBuilder
    var body: some CustomizableToolbarContent {
        ToolbarItem(id: isEdit ? InspectionMode.edit.id : InspectionMode.inspect.id, placement: placement) {
            Button {
                inspect.open(selection: context, editing: isEdit, warning: warning)
            } label: {
                Label(isEdit ? "Edit" : "Inspect", systemImage: isEdit ? "pencil" : "info.circle")
            }
        }
    }
}
public struct ElementInspectButton<W> : CustomizableToolbarContent where W: SelectionContextProtocol {
    public init(
        context: W,
        inspect: InspectionManifest<W.Element>,
        warning: SelectionWarningManifest,
        placement: ToolbarItemPlacement = .automatic
    ) {
        self.context = context;
        self.inspect = inspect;
        self.warning = warning;
        self.placement = placement
    }
    
    private let context: W;
    private let inspect: InspectionManifest<W.Element>;
    private let warning: SelectionWarningManifest;
    private let placement: ToolbarItemPlacement;
    
    @ToolbarContentBuilder
    public var body: some CustomizableToolbarContent {
        InspectionManifestToolbarButton(context: context, inspect: inspect, warning: warning, isEdit: false, placement: placement)
    }
}
public struct ElementEditButton<W> : CustomizableToolbarContent where W: SelectionContextProtocol {
    public init(
        context: W,
        inspect: InspectionManifest<W.Element>,
        warning: SelectionWarningManifest,
        placement: ToolbarItemPlacement = .automatic
    ) {
        self.context = context;
        self.inspect = inspect;
        self.warning = warning;
        self.placement = placement
    }
    
    private let context: W;
    private let inspect: InspectionManifest<W.Element>;
    private let warning: SelectionWarningManifest;
    private let placement: ToolbarItemPlacement;
    
    @ToolbarContentBuilder
    public var body: some CustomizableToolbarContent {
        InspectionManifestToolbarButton(context: context, inspect: inspect, warning: warning, isEdit: true, placement: placement)
    }
}
public struct ElementAddButton<T> : CustomizableToolbarContent {
    public init(inspect: InspectionManifest<T>, placement: ToolbarItemPlacement = .automatic) {
        self.inspect = inspect;
        self.placement = placement;
    }
    
    private let inspect: InspectionManifest<T>;
    private let placement: ToolbarItemPlacement;
    
    @ToolbarContentBuilder
    public var body: some CustomizableToolbarContent {
        ToolbarItem(id: InspectionMode.add.id, placement: placement) {
            Button {
                inspect.openAdding()
            } label: {
                Label("Add", systemImage: "plus")
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
        self.manifest = manifest;
        self.using = using;
        self.filling = filling;
        self.post = post;
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
    /// Attaches a sheet to the view that activates whenever the user marks a specific object for inspection.
    /// - Parameters:
    ///     - manifest: The ``InspectionManifest`` to pull information from.
    ///
    /// - Note: This will only activate if the inspection manifest signals it is in inspection mode. See ``InspectionManifest.isInspecting`` for more.
    func withElementInspector<T>(
        manifest: InspectionManifest<T>
    ) -> some View
    where T: InspectableElement & TypeTitled & Identifiable & NSManagedObject {
        self.modifier(WithInspectorModifier(manifest: manifest))
    }
    
    /// Attaches a sheet to the view that activates whenever the user marks a specific object for editing or adding.
    /// - Parameters:
    ///     - manifest: The ``InspectionManifest`` to pull information from.
    ///     - using: The ``NSPersistentContainer`` to add/edit information to/from. It is undefined behavior if the information being editied comes from a different container.
    ///     - filling: The closure to use for creating default values of `T`, if such an action occurs.
    ///     - post: Any actions to run after a sucessful save.
    ///
    /// - Note: This will only activate if the inspection manifest signals it is in edit or add mode. See ``InspectionManifest.isEditing`` for more.
    func withElementEditor<T>(
        manifest: InspectionManifest<T>,
        using: NSPersistentContainer = DataStack.shared.currentContainer,
        filling: @MainActor @escaping (T) -> Void,
        post: (() -> Void)? = nil
    ) -> some View
    where T: EditableElement & TypeTitled & Identifiable & NSManagedObject {
        self.modifier(WithEditorModifier(manifest: manifest, using: using, filling: filling, post: post))
    }
    
    /// Attaches a sheet to the view that activates whenever the user marks a specific object for inspection, adding, or editing.
    /// - Parameters:
    ///     - manifest: The ``InspectionManifest`` to pull information from.
    ///     - using: The ``NSPersistentContainer`` to add/edit information to/from. It is undefined behavior if the information being editied comes from a different container.
    ///     - filling: The closure to use for creating default values of `T`, if such an action occurs.
    ///     - post: Any actions to run after a sucessful save.
    func withElementIE<T>(
        manifest: InspectionManifest<T>,
        using: NSPersistentContainer = DataStack.shared.currentContainer,
        filling: @MainActor @escaping (T) -> Void,
        post: (() -> Void)? = nil
    ) -> some View
    where T: EditableElement & InspectableElement & TypeTitled & Identifiable & NSManagedObject {
        self.modifier(WithInspectorEditorModifier(manifest: manifest, using: using, filling: filling, post: post))
    }
}

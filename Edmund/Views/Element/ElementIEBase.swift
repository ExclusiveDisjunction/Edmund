//
//  ElementIEBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI
import SwiftData
import EdmundCore

@Observable
public class ElementIEManifest<T> where T: SnapshotableElement, T.ID: Sendable {
    init(_ data: T, mode: InspectionMode, unique: UniqueEngine = .init()) {
        self.data = data
        self.uniqueEngine = unique
        
        switch mode {
            case .add:
                let snap = T.makeBlankSnapshot()
                self.snapshot = snap
                self.editHash = snap.hashValue
            case .edit:
                let snap = data.makeSnapshot()
                self.snapshot = snap
                self.editHash = snap.hashValue
            case .inspect:
                self.snapshot = nil
                self.editHash = 0
        }
        
        adding = mode == .add
    }
    
    public let data: T;
    public let adding: Bool;
    public var snapshot: T.Snapshot?;
    public var editHash: Int;
    
    public var modelContext: ModelContext?;
    public var uniqueEngine: UniqueEngine;
    
    public var uniqueError: StringWarningManifest = .init()
    public var validationError: ValidationWarningManifest = .init()
    
    public var warningConfirm: Bool = false;
    
    private var _onEditChanged: ((InspectionMode) -> Void)?;
    private var _postAction: (() -> Void)?;
    
    public func onModeChanged(_ perform: ((InspectionMode) -> Void)?) {
        self._onEditChanged = perform
    }
    public func postAction(_ perform: (() -> Void)?) {
        self._postAction = perform
    }
    
    public func reset() {
        snapshot = nil
        editHash = 0
    }
    
    @MainActor
    public var isEdit: Bool {
        get {
            snapshot != nil
        }
        set {
            guard !adding && newValue != isEdit else { return } //Cannot change mode if we are adding
            
            Task {
                if newValue { //Was not editing, now is
                    let snap = data.makeSnapshot()
                    self.snapshot = snap
                    self.editHash = snap.hashValue
                }
                else { // Was editing, now is not. Must check for unsaved changes and warn otherwise.
                    guard await validate() else { return }
                    
                    if snapshot?.hashValue != editHash {
                        warningConfirm = true
                    }
                    else {
                        self.reset()
                    }
                }
            }
        }
    }
    @MainActor
    public var mode: InspectionMode {
        get {
            if adding {
                return .add
            }
            
            return isEdit ? .edit : .inspect
        }
        set {
            guard !adding && newValue != mode else { return  }
            
            switch newValue {
                case .add:
                    fallthrough
                case .edit:
                    isEdit = true
                case .inspect:
                    isEdit = false
            }
        }
    }
    
    @MainActor
    public func validate() async -> Bool {
        if let snapshot = self.snapshot, let result = await snapshot.validate(unique: uniqueEngine) {
            validationError.warning = result
            return false
        }
        
        return true
    }
    @MainActor
    public func apply() async -> Bool {
        if let editing = snapshot {
            if adding {
                modelContext?.insert(data)
                /*
                if let uniqueElement = data as? any UniqueElement {
                    let id = uniqueElement.getObjectId()
                    let wrapper = UndoAddUniqueWrapper(id: id, element: data, unique: uniqueEngine)
                    wrapper.registerWith(manager: undoManager)
                }
                else {
                    let wrapper = UndoAddWrapper(element: data)
                    wrapper.registerWith(manager: undoManager)
                }
                
                undoManager?.setActionName("add")
                 */
            }
            /*
            else {
                let previous = data.makeSnapshot();
                let wrapper = UndoSnapshotApplyWrapper(item: data, snapshot: previous, engine: uniqueEngine)
                wrapper.registerWith(manager: undoManager)
                
                undoManager?.setActionName("update")
            }
            
            undoManager?.endUndoGrouping()
             */
            
            do {
                try await data.update(editing, unique: uniqueEngine)
            }
            catch let e {
                uniqueError.warning = .init(e.localizedDescription)
                return false;
            }
        }
        
        return true
    }
    
    @MainActor
    public func submit() async -> Bool {
        if await validate() {
            if await apply() {
                return true
            }
        }
        
        return false
    }
    
    @MainActor
    private var unsavedChanges: Bool {
        isEdit && (snapshot?.hashValue ?? Int()) != editHash
    }
}

public struct DefaultElementIEFooter : View {
    @Environment(\.elementSubmit) private var elementSubmit;
    @Environment(\.elementIsEdit) private var isEdit;
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        HStack {
            Spacer()
            
            if isEdit {
                Button("Cancel", action: { dismiss() } )
                    .buttonStyle(.bordered)
            }
            
            Button(isEdit ? "Save" : "Ok", action: {
                Task {
                    if await elementSubmit() {
                        dismiss()
                    }
                }
            })
                .buttonStyle(.borderedProminent)
        }
    }
}

public struct ElementIEBase<T, Header, Footer, Inspect, Edit> : View where T: SnapshotableElement, T.ID: Sendable, Header: View, Footer: View, Inspect: View, Edit: View {
    
    public init(_ data: T, mode: InspectionMode,
                @ViewBuilder header:  @escaping (Binding<InspectionMode>) -> Header,
                @ViewBuilder footer:  @escaping () -> Footer,
                @ViewBuilder inspect: @escaping (T) -> Inspect,
                @ViewBuilder edit:    @escaping (T.Snapshot) -> Edit) {
        self.header = header
        self.footer = footer
        self.inspect = inspect
        self.edit = edit
        
        self.manifest = .init(data, mode: mode)
    }
    
    private let header: (Binding<InspectionMode>) -> Header;
    private let footer: () -> Footer;
    private let inspect: (T) -> Inspect;
    private let edit: (T.Snapshot) -> Edit;
    
    public func onModeChanged(_ perform: ((InspectionMode) -> Void)?) -> some View {
        self.manifest.onModeChanged(perform)
        return self
    }
    public func postAction(_ perform: (() -> Void)?) -> some View {
        self.manifest.postAction(perform)
        return self
    }
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.undoManager) private var undoManager;
    @Environment(\.modelContext) private var modelContext;

    @State private var warningConfirm: Bool = false;
    
    @Bindable private var manifest: ElementIEManifest<T>;
    
    @ViewBuilder
    private var confirm: some View {
        Button("Save", action: {
            warningConfirm = false //Since two sheets cannot show at the same time, we must dismiss this one first
            
            Task {
                if await manifest.apply() {
                    manifest.reset()
                }
            }
        })
        
        Button("Discard") {
            manifest.reset()
            warningConfirm = false
        }
        
        Button("Cancel", role: .cancel) {
            warningConfirm = false
        }
    }
    
    public var body: some View {
        VStack {
            self.header($manifest.mode)
            
            if let editing = manifest.snapshot {
                self.edit(editing)
            }
            else {
                self.inspect(manifest.data)
            }
            
            Spacer()
            
            self.footer()
                .environment(\.elementSubmit, .init(manifest.submit))
                .environment(\.elementIsEdit, .init(manifest.isEdit))
        }.onAppear {
            print("does the context have an undo manager? \(modelContext.undoManager != nil)")
            print("does the undo manager exist? \(undoManager != nil)")
            
            manifest.uniqueEngine = uniqueEngine
            manifest.modelContext = modelContext
        }
        .confirmationDialog("There are unsaved changes, do you wish to continue?", isPresented: $manifest.warningConfirm, titleVisibility: .visible) {
            confirm
        }
        .alert("Error", isPresented: $manifest.uniqueError.isPresented, actions: {
            Button("Ok", action: {
                manifest.uniqueError.isPresented = false
            })
        }, message: {
            Text(manifest.uniqueError.message ?? "")
        })
        .alert("Error", isPresented: $manifest.validationError.isPresented, actions: {
            Button("Ok", action: {
                manifest.validationError.isPresented = false
            })
        }, message: {
            Text((manifest.validationError.warning ?? .internalError).display)
        })
    }
}
public extension ElementIEBase where Footer == DefaultElementIEFooter {
    init(_ data: T, mode: InspectionMode,
                @ViewBuilder header:  @escaping (Binding<InspectionMode>) -> Header,
                @ViewBuilder inspect: @escaping (T) -> Inspect,
                @ViewBuilder edit:    @escaping (T.Snapshot) -> Edit) {
        self.init(
            data,
            mode: mode,
            header: header,
            footer: DefaultElementIEFooter.init,
            inspect: inspect,
            edit: edit
        )
    }
}

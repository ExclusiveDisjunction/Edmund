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
    init(_ data: T, mode: InspectionMode) {
        self.data = data
        
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
    public func changeIsEdit(newValue: Bool, unique: UniqueEngine) async {
        print("change edit called, \(newValue)")
        guard !adding && newValue != isEdit else { print("skipped"); return } //Cannot change mode if we are adding
        
        if newValue { //Was not editing, now is
            let snap = data.makeSnapshot()
            self.snapshot = snap
            self.editHash = snap.hashValue
        }
        else { // Was editing, now is not. Must check for unsaved changes and warn otherwise.
            guard await validate(unique: unique) else { return }
            
            if snapshot?.hashValue != editHash {
                warningConfirm = true
            }
            else {
                self.reset()
            }
        }
        
        print("new is edit: \(isEdit)")
    }
    @MainActor
    public func changeMode(newValue: InspectionMode, unique: UniqueEngine) async {
        print("change mode called, value: \(newValue)")
        guard !adding && newValue != mode else { return  }
        
        await changeIsEdit(newValue: newValue == .add || newValue == .edit, unique: unique)
        
        print("new mode: \(mode)")
    }
    
    @MainActor
    public var isEdit: Bool {
        snapshot != nil
    }
    @MainActor
    public var mode: InspectionMode {
        if adding {
            return .add
        }
        
        return isEdit ? .edit : .inspect
    }
    
    @MainActor
    public func validate(unique: UniqueEngine) async -> Bool {
        if let snapshot = self.snapshot, let result = await snapshot.validate(unique: unique) {
            validationError.warning = result
            return false
        }
        
        return true
    }
    @MainActor
    public func apply(context: ModelContext, undoManager: UndoManager?, unique: UniqueEngine) async -> Bool {
        print("Does the model context have an undo manager? \(context.undoManager != nil)")
        print("Does the undo manager exist? \(undoManager != nil)")
        
        if let editing = snapshot {
            undoManager?.beginUndoGrouping()
            
            if adding {
                context.insert(data)
                if let uniqueElement = data as? any UniqueElement {
                    let id = uniqueElement.getObjectId()
                    let wrapper = UndoAddUniqueWrapper(id: id, element: data, unique: unique)
                    wrapper.registerWith(manager: undoManager)
                }
                else {
                    let wrapper = UndoAddWrapper(element: data)
                    wrapper.registerWith(manager: undoManager)
                }
                
                undoManager?.setActionName("add")
            }
            else {
                let previous = data.makeSnapshot();
                let wrapper = UndoSnapshotApplyWrapper(item: data, snapshot: previous, engine: unique)
                wrapper.registerWith(manager: undoManager)
                
                undoManager?.setActionName("update")
            }
            
            undoManager?.endUndoGrouping()
            
            do {
                try await data.update(editing, unique: unique)
            }
            catch let e {
                uniqueError.warning = .init(e.localizedDescription)
                return false;
            }
        }
        
        return true
    }
    
    @MainActor
    public func submit(context: ModelContext, undoManager: UndoManager?, unique: UniqueEngine) async -> Bool {
        if await validate(unique: unique) {
            if await apply(context: context, undoManager: undoManager, unique: unique) {
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
                if isEdit {
                    Task {
                        if await elementSubmit() {
                            dismiss()
                        }
                    }
                }
                else {
                    dismiss()
                }
            })
                .buttonStyle(.borderedProminent)
        }
    }
}

public struct ElementIEBase<T, Header, Footer, Inspect, Edit> : View where T: SnapshotableElement, T.ID: Sendable, Header: View, Footer: View, Inspect: View, Edit: View {
    public init(_ data: T, mode: InspectionMode,
                @ViewBuilder header:  @escaping (InspectionMode) -> Header,
                @ViewBuilder footer:  @escaping () -> Footer,
                @ViewBuilder inspect: @escaping (T) -> Inspect,
                @ViewBuilder edit:    @escaping (T.Snapshot) -> Edit) {
        self.header = header
        self.footer = footer
        self.inspect = inspect
        self.edit = edit
        
        self.manifest = .init(data, mode: mode)
    }
    
    private let header: (InspectionMode) -> Header;
    private let footer: () -> Footer;
    private let inspect: (T) -> Inspect;
    private let edit: (T.Snapshot) -> Edit;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.undoManager) private var undoManager;
    @Environment(\.modelContext) private var modelContext;
    
    @Bindable private var manifest: ElementIEManifest<T>;
    
    public var submitAction: SubmitAction {
        .init(
            .init(
                { context, undo, unique in
                    await manifest.submit(context: context, undoManager: undo, unique: unique)
                },
                context: modelContext,
                undoManager: undoManager,
                unique: uniqueEngine)
        )
    }
    public var changeModeAction: ChangeModeAction {
        .init(
            .init(
                { mode, unique in
                    await manifest.changeMode(newValue: mode, unique: unique)
                },
                unique: uniqueEngine
            )
        )
    }
    
    public func onModeChanged(_ perform: ((InspectionMode) -> Void)?) -> some View {
        self.manifest.onModeChanged(perform)
        return self
    }
    public func postAction(_ perform: (() -> Void)?) -> some View {
        self.manifest.postAction(perform)
        return self
    }
    
    @ViewBuilder
    private var confirm: some View {
        Button("Save", action: {
            manifest.warningConfirm = false //Since two sheets cannot show at the same time, we must dismiss this one first
            
            Task {
                if await manifest.apply(context: modelContext, undoManager: undoManager, unique: uniqueEngine) {
                    manifest.reset()
                }
            }
        })
        
        Button("Discard") {
            manifest.reset()
            manifest.warningConfirm = false
        }
        
        Button("Cancel", role: .cancel) {
            manifest.warningConfirm = false
        }
    }
    
    public var body: some View {
        VStack {
            self.header(manifest.mode)
                .environment(\.elementChangeMode, changeModeAction)
            
            if let editing = manifest.snapshot {
                self.edit(editing)
            }
            else {
                self.inspect(manifest.data)
            }
            
            Spacer()
            
            self.footer()
                .environment(\.elementSubmit, submitAction)
                .environment(\.elementIsEdit, .init(manifest.isEdit))
        }.onAppear {
            print("does the context have an undo manager? \(modelContext.undoManager != nil)")
            print("does the undo manager exist? \(undoManager != nil)")
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
                @ViewBuilder header:  @escaping (InspectionMode) -> Header,
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

//
//  ElementInspectEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;
import EdmundCore

/// A wrapper around editing for a specific data type. It stores a hash (to know that a change took place), and the actual snapshot itself.
private class EditingManifest<T> : ObservableObject where T: EditableElement {
    init(_ editing: T.Snapshot?) {
        self.snapshot = editing
        self.hash = editing?.hashValue ?? Int()
    }
    @Published var snapshot: T.Snapshot?;
    @Published var hash: Int;
    
    func openWith(_ data: T) {
        self.snapshot = data.makeSnapshot()
        self.hash = self.snapshot!.hashValue
    }
    func reset() {
        self.snapshot = nil;
        self.hash = 0;
    }
}

/// A high level view that allows for switching between editing and inspecting
public struct ElementIE<T> : View where T: InspectableElement, T: EditableElement, T: PersistentModel, T: TypeTitled, T.ID: Sendable {
    /// Opens the editor with a specific mode.
    /// - Parameters:
    ///     - data: The data being passed for inspection/editing
    ///     - mode: The mode to open by default. The user can change the mode, unless the action is `add`. In this case, the user will be locked to editing mode only.
    ///     - postAction: An action to run after the editor closes, regardless of success or not.
    public init(_ data: T, mode: InspectionMode, postAction: (() -> Void)? = nil) {
        self.data = data
        self.postAction = postAction;
        self.mode = mode;
        if mode == .inspect {
            self._editing = .init(wrappedValue: .init(nil))
        }
        else {
            self._editing = .init(wrappedValue: .init( mode == .add ? T.makeBlankSnapshot() : data.makeSnapshot()))
        }
    }
    
    private let data: T;
    private let postAction: (() -> Void)?
    @State private var mode: InspectionMode;
    @State private var warningConfirm: Bool = false;
    @StateObject private var editing: EditingManifest<T>;
    
    @Bindable private var uniqueError: StringWarningManifest = .init();
    @Bindable private var validationError: BaseWarningManifest<ValidationFailure> = .init()
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.undoManager) private var undoManager;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.dismiss) private var dismiss;
    
    /// Determines if the mode is currently editing.
    private var isEdit: Bool {
        get { editing.snapshot != nil }
    }
    
    /// If in edit mode, it will determine if the input is valid. It will show an error otherwise.
    @MainActor
    private func validate() async -> Bool {
        if let snapshot = editing.snapshot, let result = await snapshot.validate(unique: uniqueEngine) {
            validationError.warning = result
            return false;
        }
        
        return true
    }
    /// Modifies the attached data to the editing snapshot, if edit mode is active.
    @MainActor
    private func apply() async -> Bool {
        if let editing = editing.snapshot {
            undoManager?.beginUndoGrouping()
            
            if mode == .add {
                modelContext.insert(data)
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
            }
            else {
                let previous = data.makeSnapshot()
                let wrapper = UndoSnapshotApplyWrapper(item: data, snapshot: previous, engine: uniqueEngine)
                wrapper.registerWith(manager: undoManager)
                
                undoManager?.setActionName("update")
            }
            
            do {
                try await data.update(editing, unique: uniqueEngine)
            }
            catch let e {
                uniqueError.warning = .init(e.localizedDescription);
                return false;
            }
            
            undoManager?.endUndoGrouping()
        }
        
        return true;
    }
    /// Validates, applies and dismisses, if the validation passes.
    @MainActor
    private func submit() {
        Task {
            if await validate() {
                if await apply() {
                    dismiss()
                }
            }
        }
    }
    /// Closes the tool window.
    private func cancel() {
        dismiss()
    }
    /// Runs the post action, if it exists.
    private func onDismiss() {
        if let postAction = postAction {
            postAction()
        }
    }
    /// Switches from inspect -> edit mode, and vice versa.
    @MainActor
    private func toggleMode() {
        Task {
            if editing.snapshot == nil {
                // Go into edit mode
                self.editing.openWith(data)
                return
            }
            
            // Do nothing if we have an invalid state.
            guard await validate() else { return }
            
            if editing.snapshot?.hashValue != editing.hash {
                warningConfirm = true
            }
            else {
                self.editing.reset()
            }
        }
    }
    
    @ViewBuilder
    private var confirm: some View {
        Button("Save", action: {
            warningConfirm = false //Since two sheets cannot show at the same time, we must dismiss this one first
            
            Task {
                if await apply() {
                    editing.reset()
                }
            }
        })
        
        Button("Discard") {
            editing.reset()
            warningConfirm = false
        }
        
        Button("Cancel", role: .cancel) {
            warningConfirm = false
        }
    }
    
    public var body: some View {
        VStack {
            InspectEditTitle<T>(mode: mode)
            
            Button(action: {
                withAnimation {
                    toggleMode()
                }
            }) {
                Image(systemName: isEdit ? "info.circle" : "pencil")
                    .resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .disabled(mode == .add) //you cannot change mode if the data is not stored.
#if os(iOS)
                .padding(.bottom)
#endif
            
            Divider()
            
            if let editing = editing.snapshot {
                T.makeEditView(editing)
            }
            else {
                data.makeInspectView()
            }
            
            Spacer()
            
            HStack{
                Spacer()
                
                if isEdit {
                    Button("Cancel", action: cancel).buttonStyle(.bordered)
                }
                
                Button(mode == .inspect ? "Ok" : "Save") {
                    if isEdit {
                        submit()
                    }
                    else {
                        cancel()
                    }
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
            .onDisappear(perform: onDismiss)
            .alert("Error", isPresented: $validationError.isPresented, actions: {
                Button("Ok", action: {
                    validationError.isPresented = false
                })
            }, message: {
                Text((validationError.warning ?? .internalError).display)
            })
            .confirmationDialog("There are unsaved changes, do you wish to continue?", isPresented: $warningConfirm) {
                confirm
            }
            .alert("Error", isPresented: $uniqueError.isPresented, actions: {
                Button("Ok", action: {
                    uniqueError.isPresented = false
                })
            }, message: {
                Text(uniqueError.message ?? "")
            })
    }
}


#Preview {
    DebugContainerView {
        ElementIE(Account.exampleAccount, mode: .inspect)
    }
}

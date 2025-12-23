//
//  ElementInspectEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import os

/*
/// A wrapper around editing for a specific data type. It stores a hash (to know that a change took place), and the actual snapshot itself.
private class EditingManifest<T> : ObservableObject where T: EditableElement {
    init(_ editing: T.Snapshot?) {
        self.snapshot = editing
        self.hash = editing?.hashValue ?? Int()
    }
    @Published var snapshot: T.Snapshot?;
    @Published var hash: Int;
    
    func openWith(_ data: T) {
        let snap = data.makeSnapshot();
        self.snapshot = snap;
        self.hash = snap.hashValue
    }
    func reset() {
        self.snapshot = nil;
        self.hash = 0;
    }
}
 */

public struct ElementIE<T> : View where T: InspectableElement & EditableElement & NSManagedObject & TypeTitled {
    
    /// Constructs the view in add mode, using a function to create a default value.
    ///  - Parameters:
    ///     - addingTo: The `NSPersistentContainer` to add to.
    ///     - filling: A closure that creates a default value of `T`, after creation.
    ///     - postAction: An optional closure to run after a successful save/dismissal is completed.
    ///
    /// Unlike ``ElementAddManifest``, this does not allow for a throwing `filling` function. If you must have a throwing function, create the manifest on your own, and use ``init(adding:postAction:)``.
    ///
    /// By default, this locks the user from switching mode to inspection.
    public init(
        addingTo: NSPersistentContainer = DataStack.shared.currentContainer,
        filling: @MainActor (T) -> Void,
        postAction: (() -> Void)? = nil
    ) {
        self.state = ElementSelectionMode.newAdd(using: addingTo, filling: filling)
        self.canChangeState = false;
        self.postAction = postAction;
        self.source = addingTo;
    }
    /// Constructs the view in add mode, using a pre-created manifest.
    /// - Parameters:
    ///     - adding: The pre-created manifest to source information from.
    ///     - postAction: An optional closure to run after a successful save/dismissal is completed.
    ///
    ///  By default, this locks the user from switching mode to inspection.
    public init(
        adding: ElementAddManifest<T>,
        postAction: (() -> Void)? = nil
    ) {
        self.state = .add(adding)
        self.canChangeState = false;
        self.postAction = postAction;
        self.source = adding.container;
    }
    public init(
        editingFrom: NSPersistentContainer = DataStack.shared.currentContainer,
        editing: T,
        postAction: (() -> Void)? = nil
    ) {
        self.state = ElementSelectionMode.newEdit(using: editingFrom, from: editing)
        self.canChangeState = true;
        self.postAction = postAction;
        self.source = editingFrom;
    }
    public init(
        edit: ElementEditManifest<T>,
        postAction: (() -> Void)? = nil
    ) {
        self.state = .edit(edit)
        self.canChangeState = true;
        self.postAction = postAction;
        self.source = edit.container;
    }
    public init(
        viewingFrom: NSPersistentContainer = DataStack.shared.currentContainer,
        viewing: T,
        postAction: (() -> Void)? = nil
    ) {
        self.state = .inspect(viewing)
        self.canChangeState = true;
        self.postAction = postAction;
        self.source = viewingFrom;
    }
    
    @State private var state: ElementSelectionMode<T>;
    @State private var warningConfirm: Bool = false;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.loggerSystem) private var loggerSystem;
    
    private var otherErrors: InternalWarningManifest = .init();
    private var validationError: ValidationWarningManifest = .init();
    
    private let canChangeState: Bool;
    private let postAction: (() -> Void)?;
    private let source: NSPersistentContainer;
    
    private var isEdit: Bool {
        switch self.state {
            case .add(_): true
            case .edit(_): true
            case .inspect(_): false
        }
    }
    private func submit(dismissOnCompletion: Bool = true) {
        do {
            switch self.state {
                case .add(let v): try v.save()
                case .edit(let v): try v.save()
                case .inspect(_):
            }
            
            if dismissOnCompletion {
                dismiss();
            }
            if let post = postAction {
                post()
            }
            
            return;
        }
        catch let e as ValidationFailure {
            self.validationError.warning = e;
            loggerSystem?.data.info("Unable to save due to non fatal validation error: \(e.localizedDescription).");
        }
        catch let e {
            self.otherErrors.warning = .init();
            loggerSystem?.data.error("Unable to save due to internal error: \(e.localizedDescription).")
        }
    }
    private func cancel() {
        switch self.state {
            case .add(let v): v.reset()
            case .edit(let v): v.reset()
            case .inspect(_):
        }
        
        dismiss();
    }
    private func switchMode() {
        guard self.canChangeState else {
            loggerSystem?.data.warning("This editor has been locked for the mode it was opened in, and cannot be changed.");
            self.otherErrors.warning = .init();
            return;
        }
        
        
    }
    private func completeTransition() {
        let newState: ElementSelectionMode<T> = switch self.state {
            case .edit(let e): .inspect(e.target)
            case .add(let e): .inspect(e.target)
            case .inspect(let e): .edit(.init(using: self.source, from: e))
        }
        
        self.state = newState;
    }
    
    public var body: some View {
        VStack {
            
        }.padding()
            .withWarning(otherErrors)
            .withWarning(validationError)
    }
}

/*
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
        self._editing = StateObject(wrappedValue: EditingManifest(
            mode == .inspect ? nil : data.makeSnapshot()
        ));
    }
    
    private let data: T;
    private let postAction: (() -> Void)?
    @State private var mode: InspectionMode;
    @State private var warningConfirm: Bool = false;
    @StateObject private var editing: EditingManifest<T>;
    
    @Bindable private var uniqueError: StringWarningManifest = .init();
    @Bindable private var validationError: WarningManifest<ValidationFailure> = .init()
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.loggerSystem) private var loggerSystem;
    
    /// Determines if the mode is currently editing.
    private var isEdit: Bool {
        get { editing.snapshot != nil }
    }
    
    /// If in edit mode, it will determine if the input is valid. It will show an error otherwise.
    @MainActor
    private func validate() async -> Bool {
        if let snapshot = editing.snapshot, snapshot.hashValue != editing.hash {
            loggerSystem?.data.debug("ElementIE determined there are unsaved edits. Attempting to validate.")
            if let result = await snapshot.validate(unique: uniqueEngine) {
                validationError.warning = result
                loggerSystem?.data.info("ElementIE could not validate the element with error \(result)")
                return false;
            }
        }
        
        return true
    }
    /// Modifies the attached data to the editing snapshot, if edit mode is active.
    @MainActor
    private func apply() async -> Bool {
        if let editing = editing.snapshot {
            if mode == .add {
                modelContext.insert(data)
            }
            
            do {
                try await data.update(editing, unique: uniqueEngine)
            }
            catch let e {
                uniqueError.warning = .init(e.localizedDescription);
                return false;
            }
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
            if let snapshot = editing.snapshot {
                loggerSystem?.data.debug("Mode toggle from edit to inspect, current vs old hash: \(snapshot.hashValue) vs \(editing.hash)")
                if snapshot.hashValue != editing.hash {
                    guard await validate() else { return }
                    
                    warningConfirm = true
                }
                else {
                    editing.reset()
                }
            }
            else {
                // Go into edit mode
                self.editing.openWith(data)
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
 */


/*
 #Preview(traits: .sampleData) {
 
 ElementIE(Account.exampleAccount, mode: .inspect)
 }
 */

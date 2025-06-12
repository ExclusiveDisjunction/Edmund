//
//  ElementInspectEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;

/// A simplification of the title used for the various Inspector and Editor views.
public struct InspectEditTitle<T> : View where T: TypeTitled {
    public init(mode: InspectionMode = .view) {
        self.mode = mode
    }
    
    @State private var mode: InspectionMode;
    
    public var body: some View {
        Text(mode == .edit ? T.typeDisplay.edit : mode == .add ? T.typeDisplay.add : T.typeDisplay.inspect)
            .font(.title2)
    }
}

/// A high level abstraction over element inspection. If `T` is an `InspectableElement`, then it will load the inspector view, and handle the layout/closing actions for the process.
public struct ElementInspector<T> : View where T: InspectableElement {
    public init(data: T) {
        self.data = data
    }
    private let data: T;
    
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            InspectEditTitle<T>()
            
            Divider()
            
            T.InspectorView(data)
            
            HStack{
                Spacer()
                
                Button("Ok", action: { dismiss() }).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

/*
public class EditUndoWrapper<T> where T: EditableElement {
    public init(item: T, snapshot: T.Snapshot) {
        self.item = item
        self.snapshot = snapshot
    }
    
    public weak var item: T?;
    
    public let snapshot: T.Snapshot;
    
    public func update(context: ModelContext) {
        if let item = self.item {
            snapshot.apply(item, context: context)
        }
    }
}
 */

/// A high level abstraction over element edting. If `T` is an `EditableElement`, then it will load the editing view, and handle the layout/closing/saving actions for the process.
public struct ElementEditor<T> : View where T: EditableElement, T: PersistentModel {
    /// Constructs the view using the specified data.
    /// - Parameters:
    ///     - data: The element to modify. A `T.Snapshot` will be created for it.
    ///     - adding: When true, the editor will understand that the `data` provided is new. Therefore, it will append it to the `ModelContext` upon successful save.
    ///     - postAction: If provided, this will be called when the editor closes, regardless of saving or not.
    public init(_ data: T, adding: Bool, postAction: (() -> Void)? = nil) {
        self.data = data
        let tmp = T.Snapshot(data)
        self.adding = adding;
        self.editing = tmp
        self.editHash = tmp.hashValue
        self.postAction = postAction
    }
    
    private var data: T;
    private let postAction: (() -> Void)?;
    private let adding: Bool;
    @Bindable private var editing: T.Snapshot;
    @State private var editHash: Int;
    @State private var alertData: [ValidationFailure]?;
    @State private var showAlert: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.undoManager) private var undoManager;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.dismiss) private var dismiss;
    
    /// Determines if the specified edit is allowed, and shows the error otherwise.
    private func validate() -> Bool {
        let result = editing.validate(unique: uniqueEngine);
        if result.isEmpty {
            alertData = nil;
            showAlert = false;
            return true;
        }
        else {
            alertData = result;
            showAlert = true;
            return false;
        }
    }
    /// Applies the data to the specified data.
    private func apply() {
        if adding {
            modelContext.insert(data)
            /*
            undoManager?.registerUndo(withTarget: data, handler: { item in
                modelContext.delete(item)
            });
             */
        }
        else {
            let previous = T.Snapshot(data);
            /*
            undoManager?.registerUndo(withTarget: EditUndoWrapper(item: data, snapshot: previous), handler: { wrapper in
                wrapper.update(context: modelContext)
            })
             */
        }
        
        editing.apply(data, context: modelContext, unique: uniqueEngine)
    }
    /// Run when the `Save` button is pressed. This will validate & apply the data (if it is valid).
    private func submit() {
        if validate() {
            apply()
            dismiss()
        }
    }
    /// Closes the popup.
    func cancel() {
        dismiss()
    }
    /// Runs the post action, if provided.
    private func onDismiss() {
        if let postAction = postAction {
            postAction()
        }
    }
    
    public var body: some View {
        VStack {
            InspectEditTitle<T>(mode: adding ? .add : .edit)
            
            Divider()
            
            T.EditView(editing)
            
            Spacer()
            
            HStack{
                Spacer()
                
                Button("Cancel", action: cancel)
                    .buttonStyle(.bordered)
                
                Button("Ok", action: submit)
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
            .alert("Error", isPresented: $showAlert, actions: {
                Button("Ok", action: {
                    showAlert = false
                })
            }, message: {
                VStack {
                    Text("The following errors have been found:")
                    ForEach(alertData ?? [], id: \.id) { data in
                        data.display
                    }
                }
            })
    }
}

/// A wrapper around editing for a specific data type. It stores a hash (to know that a change took place), and the actual snapshot itself.
private class EditingManifest<T> : ObservableObject where T: EditableElement {
    init(_ editing: T.Snapshot?) {
        self.snapshot = editing
        self.hash = editing?.hashValue ?? Int()
    }
    @Published var snapshot: T.Snapshot?;
    @Published var hash: Int;
    
    func openWith(_ data: T) {
        self.snapshot = .init(data)
        self.hash = self.snapshot!.hashValue
    }
    func reset() {
        self.snapshot = nil;
        self.hash = 0;
    }
}

/// A high level view that allows for switching between editing
public struct ElementIE<T> : View where T: InspectableElement, T: EditableElement, T: PersistentModel {
    /// Opens the editor with a specific mode.
    /// - Parameters:
    ///     - data: The data being passed for inspection/editing
    ///     - mode: The mode to open by default. The user can change the mode, unless the action is `add`. In this case, the user will be locked to editing mode only.
    ///     - postAction: An action to run after the editor closes, regardless of success or not.
    public init(_ data: T, mode: InspectionMode, postAction: (() -> Void)? = nil) {
        self.data = data
        self.postAction = postAction;
        self.mode = mode;
        if mode == .view {
            self._editing = .init(wrappedValue: .init(nil))
        }
        else {
            self._editing = .init(wrappedValue: .init(T.Snapshot(data)))
        }
    }
    
    public var data: T;
    public let postAction: (() -> Void)?
    @State private var mode: InspectionMode;
    @StateObject private var editing: EditingManifest<T>;
    @State private var showAlert: Bool = false;
    @State private var alertData: [ValidationFailure]?;
    @State private var warningConfirm: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.undoManager) private var undoManager;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.dismiss) private var dismiss;
    
    /// Determines if the mode is currently editing.
    private var isEdit: Bool {
        get { editing.snapshot != nil }
    }
    
    /// If in edit mode, it will determine if the input is valid. It will show an error otherwise.
    private func validate() -> Bool {
        if let snapshot = editing.snapshot {
            let result = snapshot.validate(unique: uniqueEngine);
            if !result.isEmpty {
                alertData = result;
                showAlert = true;
                return false;
            }
        }
        
        showAlert = false;
        alertData = nil;
        return true
    }
    /// Modifies the attached data to the editing snapshot, if edit mode is active.
    private func apply() {
        if let editing = editing.snapshot {
            //undoManager?.beginUndoGrouping()
            
            if mode == .add {
                modelContext.insert(data)
                /*
                undoManager?.registerUndo(withTarget: data, handler: { item in
                    modelContext.delete(item)
                });
                
                undoManager?.setActionName("Add")
                 */
            }
            else {
                let previous = T.Snapshot(data);
                /*
                undoManager?.registerUndo(withTarget: EditUndoWrapper(item: data, snapshot: previous), handler: { wrapper in
                    wrapper.update(context: modelContext)
                })
                
                undoManager?.setActionName("Edit")
                 */
            }
            
            editing.apply(data, context: modelContext, unique: uniqueEngine)
            
            //undoManager?.endUndoGrouping()
        }
    }
    /// Validates, applies and dismisses, if the validation passes.
    private func submit() {
        if validate() {
            apply()
            dismiss()
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
    private func toggleMode() {
        if editing.snapshot == nil {
            // Go into edit mode
            self.editing.openWith(data)
            return
        }
        
        // Do nothing if we have an invalid state.
        guard validate() else { return }
        
        if editing.snapshot?.hashValue != editing.hash {
            warningConfirm = true
        }
        else {
            self.editing.reset()
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
                T.EditView(editing)
            }
            else {
                T.InspectorView(data)
            }
            
            Spacer()
            
            HStack{
                Spacer()
                
                if isEdit {
                    Button("Cancel", action: cancel).buttonStyle(.bordered)
                }
                
                Button(mode == .view ? "Ok" : "Save", action: isEdit ? submit : cancel).buttonStyle(.borderedProminent)
            }
        }.padding()
            .onDisappear(perform: onDismiss)
            .alert("Error", isPresented: $showAlert, actions: {
                Button("Ok", action: {
                    showAlert = false
                })
            }, message: {
                VStack {
                    Text("The following errors have been found:")
                    ForEach(alertData ?? [], id: \.id) { data in
                        data.display
                    }
                }
            })
            .confirmationDialog("There are unsaved changes, do you wish to continue?", isPresented: $warningConfirm) {
                Button("Save", action: {
                    apply()
                    editing.reset()
                    warningConfirm = false
                })
                
                Button("Discard") {
                    editing.reset()
                    warningConfirm = false
                }
                
                Button("Cancel", role: .cancel) {
                    warningConfirm = false
                }
            }
    }
}

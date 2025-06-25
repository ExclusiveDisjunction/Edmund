//
//  ElementEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftUI
import SwiftData

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
    @Bindable private var uniqueError: StringWarningManifest = .init();
    @Bindable private var validationError: ValidationWarningManifest = .init()
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.undoManager) private var undoManager;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.dismiss) private var dismiss;
    
    /// Determines if the specified edit is allowed, and shows the error otherwise.
    private func validate() -> Bool {
        let result = editing.validate(unique: uniqueEngine);
        guard !result.isEmpty else {
            validationError.warning = .init(result)
            return false;
        }
        
        return true;
    }
    /// Applies the data to the specified data.
    private func apply() -> Bool {
        if adding {
            modelContext.insert(data)
            /*
             undoManager?.registerUndo(withTarget: data, handler: { item in
             modelContext.delete(item)
             });
             */
        }
        else {
            /*
             let previous = T.Snapshot(data);
             
             undoManager?.registerUndo(withTarget: EditUndoWrapper(item: data, snapshot: previous), handler: { wrapper in
             wrapper.update(context: modelContext)
             })
             */
        }
        
        do {
            try editing.apply(data, context: modelContext, unique: uniqueEngine)
        }
        catch let e {
            uniqueError.warning = .init(e.localizedDescription);
            return false;
        }
        
        return true;
    }
    /// Run when the `Save` button is pressed. This will validate & apply the data (if it is valid).
    private func submit() {
        if validate() && apply() {
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
            .alert("Error", isPresented: $validationError.isPresented, actions: {
                Button("Ok", action: {
                    validationError.isPresented = false
                })
            }, message: {
                validationError.content
            })
            .alert("Error", isPresented: $uniqueError.isPresented, actions: {
                Button("Ok", action: {
                    uniqueError.isPresented = false
                })
            }, message: {
                Text(uniqueError.message ?? "")
            })
    }
}

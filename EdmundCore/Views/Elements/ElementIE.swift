//
//  ElementInspectEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;

public struct ElementInspector<T> : View where T: InspectableElement {
    public init(data: T) {
        self.data = data
    }
    private let data: T;
    
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            Text(data.name).font(.title2)
            
            Divider().padding([.top, .bottom])
            
            T.InspectorView(data)
            
            HStack{
                Spacer()
                
                Button("Ok", action: { dismiss() }).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

public struct ElementEditor<T> : View where T: EditableElement, T: PersistentModel {
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
    @State private var showAlert: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    
    private func validate() -> Bool {
        let result = editing.validate();
        showAlert = !result
        
        return result
    }
    private func apply() {
        if adding {
            modelContext.insert(data)
        }
        
        editing.apply(data, context: modelContext)
    }
    private func submit() {
        if validate() {
            apply()
            dismiss()
        }
    }
    func cancel() {
        dismiss()
    }
    private func onDismiss() {
        if let postAction = postAction {
            postAction()
        }
    }
    
    public var body: some View {
        VStack {
            Text(data.name).font(.title2)
            
            Divider().padding([.top, .bottom])
            
            T.EditView(editing)
            
            Spacer()
            
            HStack{
                Spacer()
                
                Button("Cancel", action: cancel).buttonStyle(.bordered)
                
                Button("Ok", action: submit).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please correct fields outlined with red.")
        })
    }
}

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

public struct ElementIE<T> : View where T: InspectableElement, T: EditableElement, T: PersistentModel {
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
    @State private var warningConfirm: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    
    private var isEdit: Bool {
        get { editing.snapshot != nil }
    }
    
    private func validate() -> Bool {
        let result = editing.snapshot?.validate() ?? true
        showAlert = !result
        
        return result
    }
    private func apply() {
        if let editing = editing.snapshot {
            if mode == .add {
                modelContext.insert(data)
            }
            editing.apply(data, context: modelContext)
        }
    }
    private func submit() {
        if validate() {
            apply()
            dismiss()
        }
    }
    private func cancel() {
        dismiss()
    }
    private func onDismiss() {
        if let postAction = postAction {
            postAction()
        }
    }
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
            Text(data.name).font(.title2)
            Button(action: {
                withAnimation {
                    toggleMode()
                }
            }) {
                Image(systemName: isEdit ? "info.circle" : "pencil").resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
#if os(iOS)
                .padding(.bottom)
#endif
            
            Divider().padding([.top, .bottom])
            
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
                
                Button("Ok", action: isEdit ? submit : cancel).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please correct fields outlined with red.")
        }).confirmationDialog("There are unsaved changes, do you wish to continue?", isPresented: $warningConfirm) {
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
        }.onDisappear(perform: onDismiss)
    }
}

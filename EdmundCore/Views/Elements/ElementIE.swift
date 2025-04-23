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
    public init(_ data: T, postAction: (() -> Void)? = nil) {
        self.data = data
        let tmp = T.Snapshot(data)
        self.editing = tmp
        self.editHash = tmp.hashValue
        self.postAction = postAction
    }
    
    private var data: T;
    private let postAction: (() -> Void)?;
    private var doDestroy: Bool = false;
    @State private var editing: T.Snapshot;
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
        editing.apply(data, context: modelContext)
    }
    private func submit() {
        if validate() {
            dismiss()
        }
    }
    func cancel() {
        dismiss()
    }
    private func onDismiss() {
        if !editing.validate() && doDestroy {
            modelContext.delete(data)
        }
        
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
    
    public func destroyOnCancel() -> some View {
        var result = self;
        result.doDestroy = true;
        return result;
    }
}

public struct ElementIE<T> : View where T: InspectableElement, T: EditableElement, T: PersistentModel {
    public init(_ data: T, mode: InspectionMode, postAction: (() -> Void)? = nil) {
        self.init(data, isEdit: mode == .edit, postAction: postAction)
    }
    public init(_ data: T, isEdit: Bool,  postAction: (() -> Void)? = nil) {
        self.data = data
        self.postAction = postAction;
        if isEdit {
            let tmp = T.Snapshot(data)
            self.editing = tmp
            self.editHash = tmp.hashValue
        }
        else {
            self.editing = nil
            self.editHash = 0
        }
    }
    
    public var data: T;
    public let postAction: (() -> Void)?
    @State private var editing: T.Snapshot?;
    @State private var editHash: Int;
    @State private var showAlert: Bool = false;
    @State private var warningConfirm: Bool = false;
    
    private var doDestroy: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    
    private var isEdit: Bool {
        get { editing != nil }
    }
    
    private func validate() -> Bool {
        let result = editing?.validate() ?? true
        showAlert = !result
        
        return result
    }
    private func apply() {
        if let editing = editing {
            editing.apply(data, context: modelContext)
        }
    }
    private func submit() {
        if validate() {
            dismiss()
        }
    }
    private func cancel() {
        dismiss()
    }
    private func onDismiss() {
        if let editing = editing {
            if !editing.validate() && doDestroy {
                modelContext.delete(data)
            }
        }
        
        if let postAction = postAction {
            postAction()
        }
    }
    private func toggleMode() {
        if editing == nil {
            // Go into edit mode
            editing = .init(data)
            editHash = editing!.hashValue
            return
        }
        
        // Do nothing if we have an invalid state.
        guard validate() else { return }
        
        if editing?.hashValue != editHash {
            warningConfirm = true
        }
        else {
            self.editing = nil
        }
    }
    
    public func destroyOnCancel() -> some View {
        var result = self;
        result.doDestroy = true;
        return result;
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
            
            if let editing = editing {
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
                editing = nil
                warningConfirm = false
            })
            
            Button("Discard") {
                editing = nil
                warningConfirm = false
            }
            
            Button("Cancel", role: .cancel) {
                warningConfirm = false
            }
        }.onDisappear(perform: onDismiss)
    }
}

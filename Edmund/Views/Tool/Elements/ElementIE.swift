//
//  ElementInspectEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;

struct ElementInspector<T> : View where T: InspectableElement {
    var data: T;
    
    @Environment(\.dismiss) private var dismiss;
    
    var body: some View {
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

struct ElementEditor<T> : View where T: EditableElement {
    var data: T;
    @State private var editing: T.Snapshot;
    @State private var editHash: Int;
    @State private var showAlert: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    
    init(_ data: T) {
        self.data = data
        let tmp = T.Snapshot(data)
        self.editing = tmp
        self.editHash = tmp.hashValue
    }
    
    func validate() -> Bool {
        let result = editing.validate();
        showAlert = !result
        
        return result
    }
    func apply() {
        editing.apply(data, context: modelContext)
    }
    func submit() {
        if validate() {
            dismiss()
        }
    }
    func cancel() {
        dismiss()
    }
    
    var body: some View {
        VStack {
            Text(data.name).font(.title2)
            
            Divider().padding([.top, .bottom])
            
            T.EditView(editing)
            
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

struct ElementIE<T> : View where T: InspectableElement, T: EditableElement {
    var data: T;
    @State private var editing: T.Snapshot?;
    @State private var editHash: Int;
    @State private var showAlert: Bool = false;
    @State private var warningConfirm: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    
    init(_ data: T, mode: InspectionMode){
        self.init(data, isEdit: mode == .edit)
    }
    init(_ data: T, isEdit: Bool) {
        self.data = data
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
    
    var isEdit: Bool {
        get { editing != nil }
    }
    
    func validate() -> Bool {
        let result = editing?.validate() ?? true
        showAlert = !result
        
        return result
    }
    func apply() {
        if let editing = editing {
            editing.apply(data, context: modelContext)
        }
    }
    func submit() {
        if validate() {
            dismiss()
        }
    }
    func cancel() {
        dismiss()
    }
    func toggleMode() {
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
    
    var body: some View {
        VStack {
            Text(data.name).font(.title2)
            Button(action: toggleMode) {
                Image(systemName: isEdit ? "info.circle" : "pencil").resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.accent)
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
        }
    }
}

//
//  NamedPairParentEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI

struct NamedPairParentEdit<P> : View where P : BoundPairParent {
    @Bindable var target: P;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;
    @State private var show_red = false;
    
    @State private var workingName: String;
    @State private var editHash: Int;
    
    init(_ target: P) {
        self.target = target
        
        self.workingName = target.name
        self.editHash = target.name.hashValue
    }
    
    private func validate() -> Bool {
        if workingName.isEmpty {
            show_red = true;
            
            return false
        }
        else {
            return true
        }
    }
    private func submit() {
        if validate() {
            dismiss()
        }
    }
    
    var body : some View {
        VStack {
            HStack {
                Text("Name")
                TextField("Name", text: $workingName).onSubmit(submit).labelsHidden().textFieldStyle(.roundedBorder)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel", action: { dismiss() }).buttonStyle(.bordered)
                Button("Save", action: submit).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $show_red, actions: {
            Button("Ok", action: {
                show_red = false;
            })
        }, message: {
            Text("Please provide a name.")
        }).onDisappear {
            if target.name.isEmpty {
                modelContext.delete(target)
            }
        }
    }
}

#Preview {
    let parent = Category.exampleCategories[0];
    
    NamedPairParentEdit(parent)
}

//
//  NamedPairParentEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI

struct NamedPairParentEditor<P> : View where P : BoundPairParent {
    @Bindable var target: P;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;
    @State private var show_red = false;
    @State private var show_alert = false;
    
    var body : some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $target.name).foregroundStyle(show_red ? Color.red : Color.primary)
                }
            }
            
            HStack {
                Spacer()
                
                Button("Ok", action: {
                    if target.name.isEmpty {
                        show_red = true;
                        show_alert = true;
                    }
                    else {
                        dismiss()
                    }
                }).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $show_alert, actions: {
            Button("Ok", action: {
                show_alert = false;
            })
        }, message: {
            Text("Please provide a name for the \(P.kind.rawValue).")
        }).onDisappear {
            if target.name.isEmpty {
                modelContext.delete(target)
            }
        }
    }
}

#Preview {
    let parent = Category.exampleCategories[0];
    
    NamedPairParentEditor(target: parent)
}

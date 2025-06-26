//
//  CategoryAdder.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/25/25.
//

import SwiftUI


struct CategoryAdder : View {
    @State private var name: String = "";
    @State private var attempts: CGFloat = 0;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) private var modelContext;
    
    private func submit() {
        let name = name.trimmingCharacters(in: .whitespaces);
        
        let category = Category()
        if !name.isEmpty && category.tryNewName(name: name, unique: uniqueEngine) {
            category.setNewName(name: name, unique: uniqueEngine)
            modelContext.insert(category)
            
            dismiss()
            
            return;
        }
        
        withAnimation(.default) {
            attempts += 1;
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Name:")
                TextField("", text: $name)
                    .submitLabel(.done)
                    .onSubmit(submit)
                    .textFieldStyle(.roundedBorder)
                    .modifier(ShakeEffect(animatableData: attempts))
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel", action: { dismiss() } )
                    .buttonStyle(.bordered)
                
                Button("Done", action: submit)
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

#Preview {
    CategoryAdder()
        .modelContainer(Containers.debugContainer)
}

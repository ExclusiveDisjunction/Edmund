//
//  CategoryAdder.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/25/25.
//

import SwiftUI
import EdmundCore

struct CategoryAdder : View {
    @State private var name: String = "";
    @State private var attempts: CGFloat = 0;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) private var modelContext;
    
    @MainActor
    private func apply() async {
        let name = name.trimmingCharacters(in: .whitespaces);
        
        let category = EdmundCore.Category()
        if !name.isEmpty {
            if await category.tryNewName(name: name, unique: uniqueEngine) {
                await category.setNewName(name: name, unique: uniqueEngine)
                modelContext.insert(category)
                
                dismiss()
                return
            }
        }
        
        withAnimation(.default) {
            attempts += 1;
        }
    }
    
    @MainActor
    private func submit() {
        Task {
            await apply()
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
        .modelContainer(try! Containers.debugContainer())
}

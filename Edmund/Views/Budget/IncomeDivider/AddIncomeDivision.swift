//
//  AddIncomeDivision.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/24/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct AddIncomeDivision : View {
    @Binding var editingSnapshot: IncomeDivisionSnapshot?;
    @Binding var selection: IncomeDivision?;
    
    @State private var doCopyFrom: Bool = false;
    @State private var copyFrom: IncomeDivision? = nil;
    @State private var name: String = "";
    
    @Bindable private var warning: ValidationWarningManifest = .init();
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;
    
    private func submit() {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines);
        guard !name.isEmpty else {
            warning.warning = .empty
            return
        }
        
        let new: IncomeDivision;
        if let copyFrom = copyFrom, doCopyFrom {
            new = copyFrom.duplicate();
            new.isFinalized = false
            new.name = name;
        }
        else {
            new = .init(name: name, amount: 0, kind: .pay)
        }
        
        modelContext.insert(new);
        
        let snapshot = new.makeSnapshot()
        withAnimation {
            selection = new;
            editingSnapshot = snapshot;
        }
        dismiss()
    }
    
    var body: some View {
        VStack {
            Form {
                Toggle("Duplicate?", isOn: $doCopyFrom)
                
                if doCopyFrom {
                    IncomeDivisionPicker("Duplicate From:", selection: $copyFrom)
                }
                
                TextField("Name:", text: $name)
                    .onSubmit {
                        submit()
                    }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                
                Button("Add", action: submit)
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
            .alert("Error", isPresented: $warning.isPresented) {
                Button("Ok") {
                    warning.isPresented = false
                }
            } message: {
                Text(warning.message ?? "internalError")
            }
    }
}

#Preview {
    DebugContainerView {
        AddIncomeDivision(editingSnapshot: .constant(nil), selection: .constant(nil))
    }
}

//
//  AllBudgetMonthIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct AllBudgetMonthIE : View {
    @State private var selected: BudgetMonth? = nil;
    @State private var snapshot: BudgetMonthSnapshot? = nil;
    
    @State private var isAdding: Bool = false;
    @State private var showDeleteWarning: Bool = false;
    
    @Bindable private var warning: ValidationWarningManifest = .init();
    
    @Environment(\.loggerSystem) private var loggerSystem;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.pagesLocked) private var pagesLocked;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    private var isEditing: Bool {
        snapshot != nil
    }
    
    private func cancelEdit() {
        withAnimation {
            snapshot = nil;
        }
    }
    
    private func deletePressed() {
        if let selected = selected {
            self.selected = nil;
            self.snapshot = nil;
            
            modelContext.delete(selected)
        }
    }
    
    @MainActor
    private func submitEdit(_ snapshot: BudgetMonthSnapshot) async {
        guard let selected = selected else {
            loggerSystem?.data.warning("Submit edit was called, but there is no active snapshot or selected budget.")
            return
        }
        
        if let error = snapshot.validate(unique: uniqueEngine) {
            warning.warning = error
            return
        }
        else {
            await selected.update(snapshot, unique: uniqueEngine)
        }
        
        cancelEdit()
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                isAdding = true;
            } label: {
                Label("Add", systemImage: "plus")
            }.disabled(isEditing)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                guard let selected = selected else {
                    return
                }
                
                if let snap = snapshot {
                    Task {
                        await submitEdit(snap)
                    }
                }
                else {
                    withAnimation {
                        snapshot = selected.makeSnapshot()
                    }
                }
            } label: {
                Label(isEditing ? "Save" : "Edit", systemImage: isEditing ? "checkmark" : "pencil")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                if isEditing {
                    cancelEdit()
                }
                else {
                    showDeleteWarning = true
                }
            } label: {
                Label(isEditing ? "Cancel" : "Delete", systemImage: isEditing ? "xmark" : "trash")
                    .foregroundStyle(.red)
            }
        }
    }
    
    var body: some View {
        VStack {
            BudgetMonthPicker(selected: $selected, label: "Budget for:")
                .disabled(isEditing)
            
            if let snapshot = snapshot {
                BudgetMonthEdit(source: snapshot)
            }
            else if let selected = selected {
                BudgetMonthInspect(over: selected)
            }
            else {
                Spacer()
                
                Text("Please select a budget to begin")
                    .italic()
                
                Spacer()
            }
        }.padding()
            .navigationTitle("Budgets")
            .toolbar {
                toolbarContent
            }.toolbarRole(horizontalSizeClass == .compact ? .automatic : .editor)
            .navigationBarBackButtonHidden(isEditing)
            .onChange(of: snapshot) { _, newValue in
                pagesLocked.wrappedValue = (newValue != nil)
            }
        
            .sheet(isPresented: $isAdding) {
                BudgetMonthAdd(source: $selected, snapshot: $snapshot)
            }
        
            .alert("Error", isPresented: $warning.isPresented) {
                Button("Ok") {
                    warning.isPresented = false
                }
            } message: {
                Text(warning.message ?? "internalError")
            }
        
            .alert("Warning!", isPresented: $showDeleteWarning) {
                Button("Ok", action: deletePressed)
                
                Button("Cancel", role: .cancel) {
                    showDeleteWarning = false;
                }
            } message: {
                Text("Deleting a budget cannot be undone. Are you sure you want to continue?")
            }
    }
}

#Preview {
    DebugContainerView {
        AllBudgetMonthIE()
    }
}

//
//  BudgetIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/10/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct AllIncomeDivisionsIE : View {
    @Query(sort: [SortDescriptor(\IncomeDivision.name, order: .forward)]) private var budgetInstances: [IncomeDivision];
    @State private var selectedBudgetID: IncomeDivision.ID?;
    @State private var selectedBudget: IncomeDivision?;
    @State private var editingSnapshot: IncomeDivisionSnapshot?;
    
    @State private var showDeleteWarning: Bool = false;
    @State private var showSearching: Bool = false;
    @State private var showAdding: Bool = false;
    @State private var showGraph: Bool = false;
    @State private var finalizeWarning: Bool = false;
    
    @Bindable private var warning: ValidationWarningManifest = .init();
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.pagesLocked) private var pagesLocked;
    @Environment(\.loggerSystem) private var loggerSystem;
    
    private var isEditing: Bool {
        editingSnapshot != nil
    }
    
   
    
    @MainActor
    private func finalize(_ income: IncomeDivision) {
        
    }
    @MainActor
    private func submitEdit(_ snap: IncomeDivisionSnapshot) async {
        withAnimation {
            
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            Button {
                showGraph = true
            } label: {
                Label("Graph", systemImage: "chart.pie")
            }.disabled(selectedBudget == nil || isEditing)
        }
        
        ToolbarItem(placement: .secondaryAction) {
            Button {
                finalizeWarning = true
            } label: {
                Label("Finalize", systemImage: "square.and.arrow.up.badge.checkmark")
            }.disabled(selectedBudget == nil || isEditing)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showAdding = true;
                } label: {
                    Text("Blank")
                }
                
                Button {
                    
                } label: {
                    Text("Duplicate...")
                }
            } label: {
                Label("Add", systemImage: "plus")
            }.disabled(isEditing)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button{
                guard let budget = selectedBudget else {
                    return
                }
                
                if let snap = editingSnapshot {
                    Task {
                        await submitEdit(snap)
                    }
                }
                else {
                    withAnimation {
                        editingSnapshot = budget.makeSnapshot()
                        pagesLocked.wrappedValue = true
                    }
                }
                
            } label: {
                Label(isEditing ? "Save" : "Edit", systemImage: isEditing ? "checkmark" : "pencil")
            }.disabled(selectedBudget == nil)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showDeleteWarning = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .foregroundStyle(.red)
            }.disabled(selectedBudget == nil || isEditing)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showSearching = true;
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }.disabled(isEditing)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Income Division:")
                
                Picker("", selection: $selectedBudgetID) {
                    Text("None")
                        .tag(nil as IncomeDivision.ID?)
                    ForEach(budgetInstances, id: \.id) {
                        Text($0.name).tag($0.id)
                            .strikethrough($0.isFinalized)
                    }
                }.labelsHidden()
                    .disabled(isEditing)
                
                #if os(iOS)
                Spacer()
                #endif
            }
            
            Divider()
            
            if let snapshot = editingSnapshot {
                IncomeDivisionEdit(snapshot)
            }
            else if let budget = selectedBudget {
                IncomeDivisionInspect(data: budget)
            }
            else {
                Spacer()
                Text("Select a budget to begin")
                    .italic()
                Spacer()
                    
            }
        }.padding()
            .navigationTitle("Income Division")
            .onChange(of: selectedBudgetID) { _, newValue in
                let new: IncomeDivision?;
                if let id = newValue, let target = budgetInstances.first(where: { $0.id == id } ) {
                    target.lastViewed = .now
                    new = target
                }
                else {
                    new = nil
                }
                
                withAnimation {
                    selectedBudget = new
                }
            }
            .toolbar(content: toolbarContent)
            .toolbarRole(horizontalSizeClass == .compact ? .automatic : .editor)
            .sheet(isPresented: $showSearching) {
                AllIncomeDivisionsSearch(result: $selectedBudgetID)
            }
            .sheet(isPresented: $showAdding) {
                IncomeDivisionAdd($selectedBudgetID)
            }
            .sheet(isPresented: $showGraph) {
                if let selected = selectedBudget {
                    DevotionGroupsGraph(from: selected)
                }
                else {
                    VStack {
                        Text("internalError")
                        Button("Ok", action: { showGraph = false } )
                    }
                }
            }
            .confirmationDialog("Warning! Finalizing an income division will apply transactions to the ledger. Do you want to continue?", isPresented: $finalizeWarning, titleVisibility: .visible) {
                Button("Ok", action: {
                    if let budget = selectedBudget {
                        finalize(budget)
                    }
                    else {
                        print("Note: Division finalize was called, but the budget was not selected.")
                    }
                })
                
                Button("Cancel", role: .cancel, action: { finalizeWarning = false })
            }
            .confirmationDialog("Warning! Deleting an income division will remove all information associated with it. This action cannot be undone. Do you want to continue?", isPresented: $showDeleteWarning, titleVisibility: .visible) {
                Button("Ok") {
                    if let selectedBudget = selectedBudget {
                        withAnimation {
                            self.selectedBudgetID = nil;
                            
                            modelContext.delete(selectedBudget)
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    showDeleteWarning = false;
                }
            }
    }
}

#Preview {
    DebugContainerView {
        AllIncomeDivisionsIE()
    }
}

//
//  AllUtilitiesEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

struct UtilityInspector : View {
    var target: Utility;
    @State private var sortOrder = [KeyPathComparator(\UtilityEntry.date, order: .forward)]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    var body: some View {
        VStack {
            Text("\(target.name) Datapoints").font(.headline)
            
            List {
                ForEach(target.amounts.sorted(using: sortOrder), id: \.id) { item in
                    Text("\(item.amount, format: .currency(code: "USD")) on \(item.date.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            
            Spacer()
        }.padding()
    }
}

struct AllUtilitiesViewEdit : View {
    enum WarningKind {
        case noneSelected, editMultipleSelected
    }
    
    struct DeletingAction {
        let data: [Utility];
    }
    
    @Query var utilities: [Utility];
    @State private var tableSelected = Set<Utility.ID>();
    @State private var selectedUtility: Utility?;
    @State private var inspecting: Utility?;
    @State private var deletingAction: DeletingAction?;
    @State private var isDeleting = false;
    @State private var showWarning = false;
    @State private var warning: WarningKind = .noneSelected
    
#if os(macOS)
    @State private var showPresenter: Bool = true;
#else
    @State private var showPresenter: Bool = false;
#endif
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    private var totalPPW: Decimal {
        self.utilities.reduce(0, { $0 + $1.pricePerWeek} )
    }
    
    private func add_utility() {
        let newUtility = Utility(name: "", amounts: [])
        
        modelContext.insert(newUtility)
        self.selectedUtility = newUtility;
    }
    private func edit_utility() {
        let resolved = utilities.filter { tableSelected.contains($0.id) }
        if resolved.count == 0 {
            warning = .noneSelected
            showWarning = true
        }
        else if resolved.count == 1 {
            selectedUtility = resolved.first!
        }
        else {
            warning = .editMultipleSelected
            showWarning = true
        }
    }
    private func edit_specific(_ id: Utility.ID) {
        if let selected = utilities.first(where: { $0.id == id }) {
            selectedUtility = selected
        }
    }
    private func remove_utility() {
        let resolved = utilities.filter { tableSelected.contains($0.id) }
        if resolved.count == 0 {
            warning = .noneSelected
            showWarning = true
        }
        else {
            deletingAction = .init(data: resolved)
            isDeleting = true
        }
    }
    private func remove_specific(_ id_set: Set<Utility.ID>) {
        let filtered = utilities.filter( { id_set.contains($0.id) } );
        if !filtered.isEmpty {
            deletingAction = .init(data: filtered)
            isDeleting = true
        }
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                List {
                    ForEach(self.utilities) { utility in
                        Text("\(utility.name), \(utility.pricePerWeek, format: .currency(code: "USD"))/week").swipeActions(edge: .trailing) {
                            Button(action: {
                                deletingAction = .init(data: [utility])
                                isDeleting = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }.tint(.red)
                            
                            Button(action: {
                                selectedUtility = utility
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }.tint(.blue)
                            
                            Button(action: {
                                inspecting = utility
                                showPresenter = true
                            }) {
                                Label("Inspect", systemImage: "magnifyingglass")
                            }.tint(.green)
                        }
                    }
                }
            }
            else {
                Table(self.utilities, selection: $tableSelected) {
                    TableColumn("Name") { util in
                        Text(util.name)
                    }
                    TableColumn("Avg. Price Per Week") { util in
                        Text(util.pricePerWeek, format: .currency(code: "USD"))
                    }
                }.frame(minWidth: 300, idealWidth: 350).contextMenu(forSelectionType: Utility.ID.self) { selection in
                    
                    if let first = selection.first {
                        Button(action: {
                            edit_specific(first)
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    Button(role: .destructive) {
                        remove_specific(selection)
                    } label: {
                        Label("Delete", systemImage: "trash").foregroundStyle(.red)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Text("Total Price Per Week:")
                Text(self.totalPPW, format: .currency(code: "USD"))
            }
        }.inspector(isPresented: $showPresenter) {
            VStack {
                if let target = inspecting {
                    UtilityInspector(target: target)
                }
                else if let firstID = tableSelected.first, let target = utilities.first(where: {$0.id == firstID}) {
                    UtilityInspector(target: target)
                }
                else {
                    Spacer()
                    Text("Please select a utilitiy to view its history").italic().font(.subheadline).multilineTextAlignment(.center)
                    Spacer()
                }
            }.inspectorColumnWidth(min: 250, ideal: 300, max: 350)
        }.padding().sheet(item: $selectedUtility, content: { utility in
            UtilityEditor(utility: utility)
        }).toolbar {
            ToolbarItemGroup {
                Button(action: add_utility) {
                    Label("Add", systemImage: "plus")
                }
                
                if horizontalSizeClass != .compact {
                    Button(action: edit_utility) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: remove_utility) {
                        Label("Remove", systemImage: "trash").foregroundStyle(.red)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showPresenter.toggle()
                        }
                    }) {
                        Label(showPresenter ? "Hide Details" : "Show Details", systemImage: "sidebar.right")
                    }
                }
            }
        }.navigationTitle("Utilities").confirmationDialog("Are you sure you want to delete \(deletingAction?.data.count ?? 1 == 1 ? "this utility" : "these utilities")?", isPresented: $isDeleting, presenting: deletingAction) { action in
            Button {
                for element in action.data {
                    modelContext.delete(element)
                }
            } label: {
                Text("Remove \(action.data.count) \(action.data.count == 1 ? "utility" : "utilities")")
            }
            
            Button("Cancel", role: .cancel) {
                deletingAction = nil
            }
        }.alert("Warning", isPresented: $showWarning, actions: {
            Button("Ok", action: {
                showWarning = false
            })
        }, message: {
            switch warning {
                case .noneSelected: Text("No utility is selected, please select at least one and try again.")
                case .editMultipleSelected: Text("Cannot edit multiple utilities at once. Please only select one utility and try again.")
            }
        })
    }
}

#Preview {
    AllUtilitiesViewEdit().modelContainer(ModelController.previewContainer)
}

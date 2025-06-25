//
//  UtilityEntryVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI
import SwiftData

/// The editor view for Utility Entries.  This provides the layout for editing the entries as a series of payments & dates.
public struct UtilityEntriesEdit : View {
    @Bindable public var snapshot: UtilitySnapshot;
    @State private var selected = Set<UtilityEntry.ID>();
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    /// Removes the selected datapoints from the view.
    private func remove_selected() {
        snapshot.children.removeAll(where: { selected.contains($0.id) } )
    }
    /// Adds a new datapoint.
    private func add_new() {
        snapshot.children.append(.init(amount: 0, date: Date.now))
    }
    
    /// Creates the context menu used for the list and table elements of the view.
    @ViewBuilder
    private func selectionContextMenu(_ selection: Set<UtilityEntrySnapshot.ID>) -> some View {
        Button(action: add_new) {
            Label("Add", systemImage: "plus")
        }
        
        if !selection.isEmpty {
            Button(action: {
                withAnimation {
                    self.snapshot.children.removeAll(where: { selection.contains($0.id)} )
                }
            }) {
                Label("Remove", systemImage: "trans")
                    .foregroundStyle(.red)
            }
        }
    }
    
    public var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            HStack {
                Button(action: add_new) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                Button(action: remove_selected) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.buttonStyle(.borderless)
                
                #if os(iOS)
                EditButton()
                #endif
            }
            
            if horizontalSizeClass == .compact {
                List($snapshot.children, selection: $selected) { $child in
                    HStack {
                        CurrencyField(child.amount)
                        Text("On", comment: "[Amount] on [Date]")
                        DatePicker("", selection: $child.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                }.frame(minHeight: 300, maxHeight: .infinity)
                    .contextMenu(forSelectionType: UtilityEntrySnapshot.ID.self) { selection in
                        selectionContextMenu(selection)
                    }
            }
            else {
                Table($snapshot.children, selection: $selected) {
                    TableColumn("Amount") { $child in
                        CurrencyField(child.amount)
                    }
                    TableColumn("Date") { $child in
                        DatePicker("", selection: $child.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                }.frame(minHeight: 300, maxHeight: .infinity)
                    .contextMenu(forSelectionType: UtilityEntrySnapshot.ID.self) { selection in
                        selectionContextMenu(selection)
                    }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}


#Preview {
    UtilityEntriesEdit(snapshot: .init( Utility.exampleUtility[0] ))
        .padding()
}

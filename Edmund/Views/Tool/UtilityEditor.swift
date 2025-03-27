//
//  UtilityEditor.swift
//  Edmund
//
//  Created by Hollan on 3/26/25.
//

import SwiftUI;

struct UtilityEditorHelper : Identifiable {
    @Bindable var entry: UtilityEntry;
    @State var selected = false;
    
    var id = UUID();
}

struct UtilityEditor : View {
    @Bindable var utility: Utility;
    @Environment(\.dismiss) private var dismiss;
    @State private var nameRed = false;
    @State private var showAlert = false;
    @State private var selectedItem: UUID?;
    
    private func check_dismiss() -> Bool {
        if utility.name.isEmpty {
            nameRed = true;
            showAlert = true;
            return false;
        }
        else {
            return true;
        }
    }
    
    private func add_amount() {
        withAnimation {
            utility.amounts.append(UtilityEntry(Month.jan, 0));
        }
    }
    private func remove_amount() {
        
    }
    private func remove_id(_ id: UtilityEntry.ID) {
        utility.amounts.removeAll(where: {$0.id == id } )
    }
    private func remove_specific(_ id: IndexSet ) {
        utility.amounts.remove(atOffsets: id)
    }
    
    private var helpers: [UtilityEditorHelper] {
        utility.amounts.map( { UtilityEditorHelper(entry: $0 ) } )
    }
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text("Name")
                    if !nameRed {
                        TextField("Name", text: $utility.name)
                    }
                    else {
                        TextField("Name", text: $utility.name).border(Color.red)
                    }
                }
                
                GridRow {
                    Text("Amounts")
                    VStack {
                        List {
                            ForEach(helpers, id: \.id) { helper in
                                HStack {
                                    //Toggle("Select", isOn: helper.$selected).labelsHidden()
                                    TextField("Amount", value: helper.$entry.amount, format: .currency(code: "USD")).disabled(helper.selected)
                                }.contextMenu { // Right-click delete on macOS
                                    Button(role: .destructive) {
                                        remove_id(helper.entry.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }.onDelete(perform: remove_specific)
                        }.toolbar {
                            Button(action: add_amount) {
                                Image(systemName: "plus")
                            }
                        }.frame(minHeight: 100, maxHeight: 250)
                        Spacer()
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Ok") {
                    if check_dismiss() {
                        dismiss()
                    }
                }.buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please ensure that the name is not empty.")
        })
    }
}

#Preview {
    let utility = Utility.exampleUtilities[0];
    UtilityEditor(utility: utility)
}

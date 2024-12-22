//
//  AccountViewEdit.swift
//  Edmund
//
//  Created by Hollan on 11/4/24.
//

import SwiftUI
import SwiftData

struct PropertyRow : View {
    @Binding var property: String?
    let label: String
    @Binding var isEditing: Bool
    
    var body: some View {
        if isEditing {
            TextField("Enter Value",
                                  text: Binding(
                                    get: { property ?? "" },
                                    set: { newValue in
                                        property = newValue
                                    }
                                  )
                        ).textFieldStyle(RoundedBorderTextFieldStyle())
        } else {
            Text(property ?? "").frame(maxWidth:.greatestFiniteMagnitude, alignment: .leading)
        }
    }
}
struct ComboPropertyRow : View {
    @Binding var property: TenderType
    let label: String
    @Binding var isEditing: Bool
    
    var body: some View {
        HStack {
            Picker(selection: $property, label: EmptyView()) {
                            ForEach(TenderType.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
            .pickerStyle(MenuPickerStyle())
            .disabled(!isEditing)
        }
    }
}

struct TenderViewEdit: View {
    @Binding var tenderID: UUID?
    @State var edit: Bool
    @State var canEdit: Bool
    @State var selectedSubTender: UUID?
    
    init(target: Binding<UUID?>, editMode: Bool, enableEditing: Bool, previewTenders: [Tender]?) {
        self._tenderID = target
        self.edit = editMode
        self.canEdit = enableEditing
        self.aTenders = previewTenders
    }
    
    @Query var qTenders: [Tender]
    var aTenders: [Tender]? = nil
    var tenders: [Tender] {
        aTenders ?? qTenders
    }
    
    var tender : Tender? {
        if tenderID == nil {
            return nil
        }
        
        return tenders.first(where: { $0.id == tenderID })
    }
    
    var body: some View {
        if let ten = tender {
            VStack {
                VStack {
                    if edit {
                        TextField("Enter Name", text: Binding(
                            get: { tender?.name ?? ""},
                            set: { name in
                                tender?.name = name
                            })
                        ).textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title).frame(alignment: .center)
                    } else {
                        Text(ten.name)
                            .font(.title)
                    }
                    
                    Text(ten.accType.rawValue).font(.subheadline)
                    if canEdit {
                        Button(action: toggleEdit) {
                            Label(edit ? "Save" : "Edit", systemImage: edit ? "checkmark.seal" : "pencil")
                        }
                    }
                }
                Spacer().frame(height: 20)
                
                LazyVGrid(
                    columns:
                        [ GridItem(.fixed(100), alignment: .leading),
                          GridItem(.flexible())
                        ],
                    spacing: 10
                ) {
                    Text("Location").bold()
                    PropertyRow(property: Binding (
                        get: { tender?.loc ?? "" },
                        set: { val in
                            tender?.loc = val
                        }
                    ), label: "Location", isEditing: $edit)
                    
                    Text("Description").bold()
                    PropertyRow(property: Binding (
                        get: { tender?.desc ?? "" },
                        set: { val in
                            tender?.desc = val
                        }
                    ), label: "Description", isEditing: $edit)
                    
                    Text("Type").bold()
                    ComboPropertyRow(property: Binding (
                        get: { tender?.accType ?? TenderType.Checking },
                        set: { val in
                            tender?.accType = val
                        }), label: "Type", isEditing: $edit)
                } .padding(.leading, 10).padding(.trailing, 10)
                VStack {
                    Text("Properties").font(.subheadline)
                    
                }
                
                Spacer().frame(height: 20)
                VStack {
                    HStack {
                        Text("Sub Tenders").font(.subheadline).padding(.leading, 10)
                        Spacer()
                        HStack {
                            Button(action: addSubTender) {
                                Image(systemName: "plus")
                            }.disabled(!edit)
                            Button(action: subTenderInfo) {
                                Image(systemName: "info")
                            }.disabled(selectedSubTender == nil)
                            Button(action: removeSubTender) {
                                Image(systemName: "trash").foregroundStyle(.red)
                            }.disabled(!edit)
                        }.padding(.trailing, 10)
                    }
                    Table(of: SubTender.self, selection: $selectedSubTender) {
                        TableColumn("Name") { row in
                            Text(row.name)
                        }
                        TableColumn("Type") { row in
                            Text(row.accType.rawValue)
                        }
                        TableColumn("Balance") { row in
                            Text(row.computeBalance(), format: .currency(code: "USD"))
                        }
                    } rows: {
                        ForEach(ten.subTenders ?? []) { subTender in
                            /*
                             NavigationLink(destination: SubTenderViewEdit(subTender: subTender, edit: $edit)) {
                                 Text(subTender.description)
                             }
                             */
                            TableRow(subTender)
                        }
                    }
                }
            }.frame(minWidth: 270)
        } else {
            VStack() {
                Spacer()
                Text("Please select a tender").italic()
                Spacer()
            }.frame(minWidth: 270)
        }
    }
    
    func addSubTender() {
        
    }
    func removeSubTender() {
        
    }
    func subTenderInfo() {
        
    }
    func toggleEdit() {
        edit.toggle()
    }
}

#Preview {
    TenderViewEdit(target: .constant(Tender.exampleTender.id), editMode: false, enableEditing: true, previewTenders: [Tender.exampleTender])
}

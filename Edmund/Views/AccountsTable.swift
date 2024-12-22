//
//  AccountsTable.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

struct AccountsTable: View {
    init(previewAccounts: [Tender]? = nil) {
        pAccounts = previewAccounts
    }
    
    @Query var qAccounts: [Tender]
    var pAccounts: [Tender]?
    var accounts: [Tender] {
        pAccounts ?? qAccounts
    }
    @State private var editingLocFor: UUID?
    @State private var editMode: Bool = false
    @State private var selected: UUID?
    
    var body: some View {
        VStack {
            VStack {
                Text("Tenders").font(.largeTitle)
                HStack {
                    Button(action: addTender) {
                        Text("Add Tender")
                    }
                    Button(action: addSubTender) {
                        Text("Add Sub-Tender")
                    }
                    Button(action: removeSelected) {
                        Text("Remove Selected")
                    }
                }
            }
            HSplitView {
                Table(of: Tender.self, selection: $selected) {
                    TableColumn("Name") { row in
                        Text(row.name)
                    }
                    TableColumn("Location") { row in
                        let account = row;
                        HStack {
                            if editingLocFor == account.id {
                                TextField("Enter Location",
                                          text: Binding(
                                            get: { account.loc ?? "" },
                                            set: { newValue in
                                                if let index = accounts.firstIndex(of: account) {
                                                    accounts[index].loc = newValue
                                                }
                                            }
                                          )
                                ).textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    editingLocFor = nil
                                }
                            }
                            else {
                                Text(account.loc ?? "")
                                    .onTapGesture(count: 2) {
                                        editingLocFor = account.id
                                    }
                            }
                            
                            //Here, we are trying to make it so that items can be editied upon double click.
                        }
                    }
                    TableColumn("Type") { row in
                        Text(row.accType.toString())
                    }
                    TableColumn("Description") { row in
                        Text(row.desc ?? "")
                    }
                    
                } rows: {
                    ForEach(accounts) { row in
                        TableRow(row)
                    }
                }.frame(minWidth:400)
                ScrollView {
                    TenderViewEdit(target: $selected, editMode: false, enableEditing: true, previewTenders: pAccounts).frame(maxHeight:. infinity)
                }.frame(minWidth: 300, maxHeight: .infinity)
            }
        }
    }
    
    private func addTender() -> Void {

    }
    private func addSubTender() -> Void {
        
    }
    private func removeSelected() -> Void {
        
    }
}

#Preview {
    AccountsTable(previewAccounts: Tender.exampleTenders).frame(width:800, height:400)
}

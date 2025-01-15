//
//  AccountsVE.swift
//  Edmund
//
//  Created by Hollan on 1/8/25.
//

import SwiftUI
import SwiftData

struct AccountsVE : View {
    @Query private var accounts: [Account];
    @State private var selected: UUID?;
    @State private var alert: AlertContext = .init()
    @State private var editing: Bool = false;
    
    private func add_account() {
        
    }
    private func remove_account() {
        
    }
    private func add_sub_account(to: UUID) {
        
    }
    private func remove_sub_account(to: UUID) {
        
    }
    
    var body : some View {
        VStack {
            HStack {
                Text("Accounts").font(.title)
                Spacer()
            }
            HStack {
                Button(action: {
                    editing.toggle()
                }) {
                    Label(editing ? "View" : "Edit", systemImage: editing ? "eye" : "pencil")
                }
            }
            
            ScrollView {
                ForEach(accounts) { account in
                    VStack {
                        HStack {
                            Text("\(account.name)").font(.title3)
                            Spacer()
                        }
                        ForEach(account.children) { child in
                            HStack {
                                Text("\(child.name)")
                                Spacer()
                            }.padding(.leading, 10)
                        }
                    }
                    Divider()
                }
            }
        }.padding()
    }
}

#Preview {
    AccountsVE().modelContainer(ModelController.previewContainer)
}

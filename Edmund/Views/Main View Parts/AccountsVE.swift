//
//  AccountsVE.swift
//  Edmund
//
//  Created by Hollan on 1/8/25.
//

import SwiftUI
import SwiftData

struct AccountsVE : View {
    @Query var accounts: [Account];
    @State var selected: UUID?;
    @State var alert: AlertContext = .init()
    
    private func refresh() {
        
    }
    private func add_account() {
        
    }
    private func remove_account() {
        
    }
    private func add_sub_account() {
        
    }
    private func remove_sub_account() {
        
    }
    
    var body : some View {
        VStack {
            Text("Accounts").font(.title)
            
            HSplitView {
                Table(accounts, selection: $selected) {
                    TableColumn("Name") {
                        Text($0.name)
                    }
                    TableColumn("Total Sub Accounts") {
                        Text("\($0.children.count)")
                    }
                }
                
                VStack {
                    if let sel = accounts.first(where: { $0.id == selected }) {
                        Text("Account \(sel.name)")
                        
                        
                    }
                    else {
                        Text("Please select an account to view its contents").italic().font(.footnote)
                    }
                }
            }
        }.padding().onAppear(perform: refresh)
    }
}

#Preview {
    AccountsVE()
}

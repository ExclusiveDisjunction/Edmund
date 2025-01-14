//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

struct AccountPicker : View {
    init(names: NamedPair = .init()) {
        self.names = names
        self.selectedID = nil;
    }
    
    @State private var selectedID: UUID?;
    @State private var names: NamedPair;
    @State private var prev_selected_hash: Int? = nil;
    
    @State private var showing_sheet: Bool = false;
    
    @Query private var accounts: [SubAccount];

    func get_account() -> SubAccount? {
        if let sel = selectedID {
            if names.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                return accounts.first(where: { $0.id == sel })
            }
        }
        
        //Otherwise, we will look up our target based on the texts given
        return accounts.first(where: { $0.parent.name == names.name && $0.name == names.sub_name} )
    }
    private func dismiss_sheet(action: NamedPickerAction) {
        switch action {
        case .cancel:
            names = .init();
            selectedID = nil;
            prev_selected_hash = nil;
            showing_sheet = false;
            
        case .ok:
            if let sel = selectedID, let acc = accounts.first(where: { $0.id == sel } ) {
                self.names = .init(acc.parent.name, acc.name)
                self.prev_selected_hash = names.hashValue;
            }
            
            showing_sheet = false;
        }
    }
    
    var body: some View {
        HStack {
            NamedPairEditor(pair: $names, parent_name: "Account", child_name: "Sub Account")
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            PickerSheet(selectedID: $selectedID, mode: .account, elements: accounts.to_named_pair(), on_dismiss: dismiss_sheet)
        }
    }
}
struct SubAccountViewer : View {
    var account: SubAccount;
    
    var body : some View {
        Text("\(account.parent.name), \(account.name)")
    }
}

#Preview {
    let account: Account = .init("Checking")
    let sub_acc: SubAccount = .init("DI", parent: account)
    
    VStack {
        AccountPicker()
        SubAccountViewer(account: sub_acc)
    }
}

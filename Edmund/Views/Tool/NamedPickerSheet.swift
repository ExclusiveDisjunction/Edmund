//
//  NamedPickerSheet.swift
//  Edmund
//
//  Created by Hollan on 1/10/25.
//

import SwiftUI;
import SwiftData;

enum NamedPairPickerMode {
    case account
    case category
}

struct PickerSheet : View {
    @Binding var selectedID: UUID?;
    @State var mode: NamedPairPickerMode;
    
    @Query var accounts: [Account];
    @Query private var categories: [Category];
    
    var body: some View {
        switch mode {
        case .account:
            if !accounts.isEmpty {
                Picker("Account", selection: $selectedID) {
                    Text("None").tag(nil as UUID?)
                    ForEach(accounts) { account in
                        ForEach(account.children) { sub_account in
                            SubAccountViewer(account: sub_account).tag(sub_account.id as UUID?)
                        }
                    }
                }
            }
            else {
                Text("There are no accounts to pick from, please add one").italic()
            }
        case .category:
            Picker("Category", selection: $selectedID) {
                
            }
        }
    }
}

#Preview {
    var selected: UUID? = nil;

    let selected_bind = Binding<UUID?>(
        get: {
            selected
        },
        set: {
            selected = $0
        }
    )
    
    if let selected = selected {
        Text("Selected: \(selected.uuidString)")
    }
    else {
        Text("None Selected")
    }
    PickerSheet(selectedID: selected_bind, mode: .account)
}

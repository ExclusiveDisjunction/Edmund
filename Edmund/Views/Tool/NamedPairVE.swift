//
//  AccPair.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI;
import SwiftData;

struct NamedPair: Hashable {
    init(_ name: String = "", _ sub_name: String = "") {
        self.name = name;
        self.sub_name = sub_name;
    }
    
    static func ==(lhs: NamedPair, rhs: NamedPair) -> Bool {
        return lhs.name == rhs.name && lhs.sub_name == rhs.sub_name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(sub_name)
    }
    
    @State var name: String;
    @State var sub_name: String;
}

struct AccountPicker : View {
    init(_ mode: NamedPairPickerMode, names: NamedPair = .init()) {
        self.mode = mode
        self.names = names
    }
    
    @State private var selectedID: UUID? = nil;
    @State private var names: NamedPair = .init()
    @State private var mode: NamedPairPickerMode;
    @State private var showing_sheet: Bool = false;
    @State private var prev_selected_hash: Int? = nil;
    
    @Query private var accounts: [SubAccount];

    func get_account() -> SubAccount? {
        if let sel = selectedID {
            if names.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                return accounts.first(where: { $0.id == sel })
            }
            
            
        }
    }
    func dismiss_sheet() {
        if let sel = selectedID, let acc = accounts.first(where: { $0.id == sel } ) {
            self.names = .init(acc.parent.name, acc.name)
            self.prev_selected_hash = names.hashValue;
        }
        
        showing_sheet = false;
    }
    
    var body: some View {
        HStack {
            if mode == .account {
                TextField("Account", text: $names.name)
                TextField("Sub Account", text: $names.sub_name)
            }
            else {
                
            }
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            VStack {
                PickerSheet(selectedID: $selectedID, mode: mode).padding()
                HStack {
                    Spacer()
                    Button("Ok", action: dismiss_sheet)
                    Button("Cancel & Clear", action: {
                        names = .init();
                        selectedID = nil;
                        prev_selected_hash = nil;
                        dismiss_sheet()
                    }).foregroundStyle(.red)
                }
            }
        }
    }
}
struct SubAccountViewer : View {
    var account: SubAccount;
    
    var body : some View {
        Text("\(account.parent.name), \(account.name)")
    }
}
struct CategoryPicker : View {
    var body: some View {
        Text("not yet")
    }
}
struct SubCategoryViewer : View {
    var category: SubCategory;
    
    var body: some View {
        Text("\(category.parent.name), \(category.name)")
    }
}

#Preview {
    var account: Account = .init("Checking")
    var sub_acc: SubAccount = .init("", parent: account)
    var cat: Category = .init("Account Control")
    var sub_cat: SubCategory = .init("Pay", parent: cat)
    
    let acc_bind: Binding<SubAccount> = .init(
        get: {
            sub_acc
        },
        set: {
            sub_acc = $0
        }
    )
    let cat_bind: Binding<SubCategory> = .init(
        get: {
            sub_cat
        },
        set: {
            sub_cat = $0
        }
    )
    
    VStack {
        AccountPicker(.account, names: ("Checking", ""))
        SubAccountViewer(account: sub_acc)
        Divider()
        //CategoryPicker()
        SubCategoryViewer(category: sub_cat)
    }
}

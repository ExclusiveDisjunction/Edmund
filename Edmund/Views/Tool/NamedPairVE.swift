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
    
    var isEmpty: Bool {
        name.isEmpty || sub_name.isEmpty
    }
    
    @State var name: String;
    @State var sub_name: String;
}

struct NamedPairViewer : View {
    @State var pair: NamedPair;
    
    var body: some View {
        Text("\(pair.name), \(pair.sub_name)")
    }
}

extension [SubAccount] {
    func to_named_pair() -> [NamedPair] {
        self.reduce(into: []) { $0.append(.init($1.parent.name, $1.name)) }
    }
    func to_uuid_list() -> [UUID] {
        self.reduce(into: []) { $0.append($1.id) }
    }
    func to_uuid_named_pair() -> Dictionary<UUID, NamedPair> {
        self.reduce(into: [:]) { $0[$1.id] =  NamedPair($1.parent.name, $1.name) }
    }
}
extension [SubCategory] {
    func to_named_pair() -> [NamedPair] {
        self.reduce(into: []) { $0.append(.init($1.parent.name, $1.name)) }
    }
    func to_uuid_list() -> [UUID] {
        self.reduce(into: []) { $0.append($1.id) }
    }
    func to_uuid_named_pair() -> Dictionary<UUID, NamedPair> {
        self.reduce(into: [:]) { $0[$1.id] =  NamedPair($1.parent.name, $1.name) }
    }
}

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
    func dismiss_sheet() {
        if let sel = selectedID, let acc = accounts.first(where: { $0.id == sel } ) {
            self.names = .init(acc.parent.name, acc.name)
            self.prev_selected_hash = names.hashValue;
        }
        
        showing_sheet = false;
    }
    
    var body: some View {
        HStack {
            TextField("Account", text: $names.name)
            TextField("Sub Account", text: $names.sub_name)
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            VStack {
                PickerSheet(selectedID: $selectedID, mode: .account, elements: accounts.to_uuid_named_pair()).padding()
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
    init(names: NamedPair = .init()) {
        self.names = names
        self.selectedID = nil;
    }
    
    @State private var selectedID: UUID?;
    @State private var names: NamedPair;
    @State private var prev_selected_hash: Int? = nil;
    
    @State private var showing_sheet: Bool = false;
    
    @Query private var categories: [SubCategory];

    func get_account() -> SubCategory? {
        if let sel = selectedID {
            if names.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                return categories.first(where: { $0.id == sel })
            }
        }
        
        //Otherwise, we will look up our target based on the texts given
        return categories.first(where: { $0.parent.name == names.name && $0.name == names.sub_name} )
    }
    func dismiss_sheet() {
        if let sel = selectedID, let acc = categories.first(where: { $0.id == sel } ) {
            self.names = .init(acc.parent.name, acc.name)
            self.prev_selected_hash = names.hashValue;
        }
        
        showing_sheet = false;
    }
    
    var body: some View {
        HStack {
            TextField("Account", text: $names.name)
            TextField("Sub Account", text: $names.sub_name)
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            VStack {
                PickerSheet(selectedID: $selectedID, mode: .account, elements: categories.to_uuid_named_pair()).padding()
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
struct SubCategoryViewer : View {
    var category: SubCategory;
    
    var body: some View {
        Text("\(category.parent.name), \(category.name)")
    }
}

#Preview {
    let account: Account = .init("Checking")
    let sub_acc: SubAccount = .init("", parent: account)
    let cat: Category = .init("Account Control")
    let sub_cat: SubCategory = .init("Pay", parent: cat)
    
    VStack {
        AccountPicker(names: .init("Checking", ""))
        SubAccountViewer(account: sub_acc)
        Divider()
        CategoryPicker()
        SubCategoryViewer(category: sub_cat)
    }
}

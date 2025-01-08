//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

@Model
class LedgerEntry : ObservableObject, Identifiable
{
    init(memo: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category: SubCategory, account: SubAccount) {
        self.id = UUID()
        self.memo = memo
        self.credit = credit
        self.debit = debit
        self.date = date
        self.added_on = added_on;
        self.location = location
        self.category = category
        self.account = account
    }
    
    var id: UUID;
    var memo: String;
    var credit: Decimal;
    var debit: Decimal;
    var date: Date;
    var added_on: Date;
    var location: String;
    @Relationship(deleteRule: .nullify, inverse: nil) var category: SubCategory;
    @Relationship(deleteRule: .nullify, inverse: nil) var account: SubAccount;
    
    var account_name: String {
        account.parent.name
    }
    var sub_account_name: String {
        account.name
    }
    var category_name: String {
        category.parent.name
    }
    var sub_category_name: String {
        category.name
    }
}

@Model
class Category : Identifiable, Hashable {
    init(_ name: String = "") {
        self.name = name
    }
    
    static func ==(lhs: Category, rhs: Category) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var id: UUID = UUID();
    @Attribute(.unique) var name: String;
    @Relationship var children = [SubCategory]();
    
    var isEmpty: Bool {
        name.isEmpty
    }
}
@Model
class SubCategory : Identifiable, Hashable {
    init(_ name: String , parent: Category) {
        self.parent = parent
        self.name = name
    }
    
    static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        lhs.parent == rhs.parent && lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(name)
    }
    
    var id: UUID = UUID();
    @Relationship(deleteRule: .cascade, inverse: \Category.children) var parent: Category;
    var name: String;
    
    var isEmpty: Bool {
        parent.isEmpty || name.isEmpty
    }
}

@Model
class Account : Identifiable, Hashable {
    init(_ name: String) {
        self.name = name;
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var id: UUID = UUID();
    @Attribute(.unique) var name: String;
    @Relationship var children = [SubAccount]();
    
    var isEmpty : Bool {
        name.isEmpty
    }
}
@Model
class SubAccount : Identifiable, Hashable {
    init(_ name: String, parent: Account) {
        self.name = name
        self.parent = parent
    }
    
    static func ==(lhs: SubAccount, rhs: SubAccount) -> Bool {
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    
    var id: UUID = UUID();
    @Attribute(.unique) var name: String;
    @Relationship(deleteRule: .cascade, inverse: \Account.children) var parent: Account;
}

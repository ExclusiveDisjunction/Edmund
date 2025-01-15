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
    @Relationship(deleteRule: .cascade, inverse: nil) var category: SubCategory;
    @Relationship(deleteRule: .cascade, inverse: nil) var account: SubAccount;
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
    @Relationship(deleteRule: .cascade) var children = [SubCategory]();
    
    static let exampleCategories: [Category] = {
        let result = [
            Category("Food"),
            Category("Bill"),
            Category("Account Control")
        ]
        
        for cat in result {
            cat.children.append(contentsOf: ["One", "Two", "Three"].map( { SubCategory.init($0, parent: cat) } ) )
        }
        
        return result;
    }()
    
    var isEmpty: Bool {
        name.isEmpty
    }
}
@Model
class SubCategory : NamedPair {
    init(_ name: String , parent: Category, id: UUID = UUID()) {
        self.parent = parent
        self.name = name
        self.id = id
    }
    
    static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        lhs.parent == rhs.parent && lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(name)
    }
    
    @Attribute(.unique) var id: UUID;
    @Relationship(deleteRule: .cascade, inverse: \Category.children) var parent: Category;
    var name: String;
    
    var isEmpty: Bool {
        parent.isEmpty || name.isEmpty
    }
    
    var parent_name: String {
        get { parent.name }
        set(v) { parent.name = v}
    }
    var child_name: String {
        get { name }
        set(v) { name = v }
    }
    static var kind: NamedPairKind {
        get { .category }
    }
}

@Model
class Account : Identifiable, Hashable {
    init(_ name: String, creditLimit: Decimal? = nil) {
        self.name = name;
        self.creditLimit = creditLimit;
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var id: UUID = UUID();
    @Attribute(.unique) var name: String;
    @Attribute var creditLimit: Decimal?;
    @Relationship(deleteRule: .cascade) var children = [SubAccount]();
    
    var isEmpty : Bool {
        name.isEmpty
    }
    
    static var exampleAccounts: [Account] {
        let accounts: [Account] = ["Checking", "Savings", "Savor"].map({ Account($0) });
        accounts[0].creditLimit = 400;
        for account in accounts {
            account.children = ["DI", "Hold", "Bills"].map( { SubAccount($0, parent: account) })
        }
        
        return accounts;
    }
}
@Model
class SubAccount : NamedPair {
    init(_ name: String, parent: Account, id: UUID = UUID()) {
        self.name = name
        self.parent = parent
        self.id = id;
    }
    
    static func ==(lhs: SubAccount, rhs: SubAccount) -> Bool {
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    
    @Attribute(.unique) var id: UUID;
    var name: String;
    @Relationship(deleteRule: .cascade, inverse: \Account.children) var parent: Account;
    
    var isEmpty: Bool {
        name.isEmpty || parent.name.isEmpty
    }
    
    var parent_name: String {
        get { parent.name }
        set(v) { parent.name = v}
    }
    var child_name: String {
        get { name }
        set(v) { name = v }
    }
    static var kind: NamedPairKind {
        get { .account }
    }
}

//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData

@Model
class Category : Identifiable, Hashable {
    init(_ name: String = "") {
        self.name = name
        self.id = UUID()
    }
    
    static func ==(lhs: Category, rhs: Category) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var id: UUID;
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

struct AcctCtlContext {
    let pay: SubCategory;
    let transfer: SubCategory;
    let audit: SubCategory;
    let gift: SubCategory;
    let interest: SubCategory;
}
struct PaymentsTransContext {
    let refund: SubCategory;
    let loan: SubCategory;
    let repayment: SubCategory;
    let bill: SubCategory;
}

/// Provides a lookup for the basic SubCategories that are used by the program. 
class CategoriesContext {
    private static func insert(into: ModelContext, parent: String, child: String) -> SubCategory {
        let result = SubCategory(child, parent: Category(parent))
        
        into.insert(result)
        
        return result;
    }
    
    init(from: [SubCategory], context: ModelContext) {
        /*
         The context must contain:
         
         Account Control
            Pay
            Transfer
            Audit
            Gift
            Interest
         Payment
            Refund
            Loan
            Repayment
            Bill
         
         */
        var account_control: Dictionary<String, SubCategory> = [:];
        var payment: Dictionary<String, SubCategory> = [:];
        
        for sub_cat in from {
            switch sub_cat.parent.name {
            case "Account Control":
                account_control[sub_cat.name] = sub_cat;
            case "Payment":
                payment[sub_cat.name] = sub_cat;
            default: continue;
            }
        }
        
        //First I will do accounts
        let pay: SubCategory = account_control["Pay"] ?? CategoriesContext.insert(into: context, parent: "Account Control", child: "Pay")
        let transfer: SubCategory = account_control["Transfer"] ?? CategoriesContext.insert(into: context, parent: "Account Control", child: "Transfer")
        let audit: SubCategory = account_control["Audit"] ?? CategoriesContext.insert(into: context, parent: "Account Control", child: "Audit")
        let gift: SubCategory = account_control["Gift"] ?? CategoriesContext.insert(into: context, parent: "Account Control", child: "Gift")
        let interest: SubCategory = account_control["Interest"] ?? CategoriesContext.insert(into: context, parent: "Account Control", child: "Interest")
        
        self.account_control = .init(pay: pay, transfer: transfer, audit: audit, gift: gift, interest: interest)
        
        //Then payments
        let refund: SubCategory = account_control["Refund"] ?? CategoriesContext.insert(into: context, parent: "Payment", child: "Refund")
        let loan: SubCategory = account_control["Loan"] ?? CategoriesContext.insert(into: context, parent: "Payment", child: "Loan")
        let repayment: SubCategory = account_control["Repayment"] ?? CategoriesContext.insert(into: context, parent: "Payment", child: "Repayment")
        let bill: SubCategory = account_control["Bill"] ?? CategoriesContext.insert(into: context, parent: "Payment", child: "Bill")
        
        self.payments = .init(refund: refund, loan: loan, repayment: repayment, bill: bill)
    }
    
    var account_control: AcctCtlContext;
    var payments: PaymentsTransContext;
}

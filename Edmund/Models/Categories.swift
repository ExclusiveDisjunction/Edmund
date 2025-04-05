//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData

@Model
public final class Category : Identifiable, Hashable, BoundPairParent {
    public required init() {
        self.name = ""
        self.children = []
    }
    public init(_ name: String = "", children: [SubCategory] = []) {
        self.name = name
        self.children = children;
    }
    
    public static func ==(lhs: Category, rhs: Category) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public var id: String { name }
    @Attribute(.unique) public var name: String;
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent) public var children: [SubCategory];

    public static var kind: NamedPairKind { .category }
    
    #if DEBUG
    public static let exampleCategories: [Category] = {
        [
            exampleCategory,
            .init("Account Control", children: [
                .init("Transfer"),
                .init("Pay"),
                .init("Audit"),
                .init("Initial")
            ]),
            .init("Personal", children: [
                .init("Dining"),
                .init("Entertainment")
            ]),
            .init("Home", children: [
                .init("Groceries"),
                .init("Health"),
                .init("Decor"),
                .init("Repairs")
            ]),
            .init("Car", children: [
                .init("Gas"),
                .init("Maintenence"),
                .init("Decor")
            ])
        ]
    }()
    public static let exampleCategory: Category = {
        .init("Bills", children: [
            .init("Utilities"),
            .init("Subscriptions"),
            .init("Bills")
        ])
    }()
    #endif
    
    public var isEmpty: Bool {
        name.isEmpty
    }
}
@Model
public class SubCategory : BoundPair, Equatable {
    public required init() {
        self.parent = nil
        self.name = ""
        self.id = UUID()
        self.transactions = []
    }
    public required init(parent: Category?) {
        self.parent = parent
        self.name = ""
        self.id = UUID()
        self.transactions = []
    }
    public init(_ name: String, parent: Category? = nil, id: UUID = UUID(), transactions: [LedgerEntry] = []) {
        self.parent = parent
        self.name = name
        self.id = id
        self.transactions = transactions
    }
    
    public static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(name)
    }
    
    @Attribute(.unique) public var id: UUID;
    @Relationship public var parent: Category?;
    public var name: String;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category) public var transactions: [LedgerEntry];

    
    public var isEmpty: Bool {
        parent?.isEmpty ?? false || name.isEmpty
    }
    
    public static var kind: NamedPairKind {
        get { .category }
    }
    
    #if DEBUG
    static let exampleSubCategory: SubCategory = .init("Utilities", parent: .init("Bills"))
    #endif
}

public struct AcctCtlContext {
    let pay: SubCategory;
    let transfer: SubCategory;
    let audit: SubCategory;
    let gift: SubCategory;
    let interest: SubCategory;
}
public struct PaymentsTransContext {
    let refund: SubCategory;
    let loan: SubCategory;
    let repayment: SubCategory;
    let bill: SubCategory;
}


/// Provides a lookup for the basic SubCategories that are used by the program.
public class CategoriesContext {
    private static func insert(into: ModelContext, parent: String, child: String) -> SubCategory {
        let result = SubCategory(child, parent: Category(parent))
        
        into.insert(result)
        
        return result;
    }
    
    public init(from: [SubCategory], context: ModelContext) {
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
            switch sub_cat.parent?.name ?? "" {
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
    
    public var account_control: AcctCtlContext;
    public var payments: PaymentsTransContext;
}

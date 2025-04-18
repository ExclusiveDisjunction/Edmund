//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

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

protocol CategoriesHolderBasis {
    init?(context: ModelContext, from: Category?)
    static var name: String { get }
}
extension CategoriesHolderBasis {
    static func getOrInsert(from: Category, name: String, context: ModelContext) -> SubCategory {
        if let target = from.children.first(where: {$0.name == name } ) {
            return target
        }
        else {
            let result = SubCategory(name, parent: from)
            context.insert(result)
            
            return result
        }
    }
}

@Observable
public class AccountControlCategories : CategoriesHolderBasis {
    init(pay: SubCategory, transfer: SubCategory, audit: SubCategory) {
        self.pay = pay
        self.transfer = transfer
        self.audit = audit
    }
    required convenience init?(context: ModelContext, from: Category?) {
        if let from = from {
            self.init(
                pay: Self.getOrInsert(from: from, name: "Pay", context: context),
                transfer: Self.getOrInsert(from: from, name: "Transfer", context: context),
                audit: Self.getOrInsert(from: from, name: "Audit", context: context)
            )
        }
        else {
            let parent = Category(Self.name)
            self.init(
                pay: .init("Pay", parent: parent),
                transfer: .init("Transfer", parent: parent),
                audit: .init("Audit", parent: parent)
            )
            context.insert(parent)
        }
    }
    
    static var name: String { "Account Control" }
    
    let pay: SubCategory;
    let transfer: SubCategory;
    let audit: SubCategory;
}

@Observable
public class PaymentsCategories : CategoriesHolderBasis {
    init(loan: SubCategory, repayment: SubCategory, refund: SubCategory, gift: SubCategory, interest: SubCategory) {
        self.loan = loan
        self.repayment = repayment
        self.refund = refund
        self.gift = gift
        self.interest = interest
    }
    required convenience init?(context: ModelContext, from: Category?) {
        if let from = from {
            self.init(
                loan: Self.getOrInsert(from: from, name: "Loan", context: context),
                repayment: Self.getOrInsert(from: from, name: "Repayment", context: context),
                refund: Self.getOrInsert(from: from, name: "Refund", context: context),
                gift: Self.getOrInsert(from: from, name: "Gift", context: context),
                interest: Self.getOrInsert(from: from, name: "Interest", context: context)
            )
        }
        else {
            let parent = Category(Self.name)
            self.init(
                loan: .init("Loan"),
                repayment: .init("Repayment"),
                refund: .init("Refund"),
                gift: .init("Gift"),
                interest: .init("Interest")
            )
            
            parent.children = [
                loan,
                repayment,
                refund,
                gift,
                interest
            ]
            context.insert(parent)
        }
    }
    
    static var name: String { "Payments" }
    
    let loan: SubCategory;
    let repayment: SubCategory;
    let refund: SubCategory;
    
    let gift: SubCategory;
    let interest: SubCategory;
}

@Observable
public class BillPaymentsCategories : CategoriesHolderBasis{
    init(bill: SubCategory, sub: SubCategory, utility: SubCategory) {
        self.bill = bill
        self.subscription = sub
        self.utility = utility
    }
    required convenience init?(context: ModelContext, from: Category?) {
        if let from = from {
            self.init(
                bill: Self.getOrInsert(from: from, name: "Bill", context: context),
                sub: Self.getOrInsert(from: from, name: "Subscription", context: context),
                utility: Self.getOrInsert(from: from, name: "Utility", context: context)
            )
        }
        else {
            let parent = Category(Self.name)
            self.init(
                bill: .init("Bill"),
                sub: .init("Subscription"),
                utility: .init("Utility")
            )
            
            parent.children = [
                bill,
                subscription,
                utility,
            ]
            context.insert(parent)
        }
    }
    
    static let name: String = "Bills"
    
    let bill: SubCategory;
    let subscription: SubCategory;
    let utility: SubCategory;
}

/// Provides a lookup for the basic SubCategories that are used by the program.
@Observable
public class CategoriesContext {
    init?(_ context: ModelContext) {
        guard let categories = try? context.fetch(FetchDescriptor<Category>()) else { return nil }
        
        guard let acc = AccountControlCategories(context: context, from: categories.first(where: {$0.name == AccountControlCategories.name } ) ) else { return nil }
        guard let payment = PaymentsCategories(context: context, from: categories.first(where: {$0.name == PaymentsCategories.name } ) ) else { return nil }
        guard let bills = BillPaymentsCategories(context: context, from: categories.first(where: {$0.name == BillPaymentsCategories.name } ) ) else { return nil }
        
        self.context = context
        self.accountControl = acc
        self.payments = payment
        self.bills = bills
    }
    
    private var context: ModelContext;
    public var accountControl: AccountControlCategories;
    public var payments: PaymentsCategories;
    public var bills: BillPaymentsCategories;
}

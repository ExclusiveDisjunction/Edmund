//
//  CategoryContext.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import SwiftData
import SwiftUI

public protocol CategoriesHolderBasis {
    @MainActor
    init?(context: ModelContext, from: Category?)
    static var name: String { get }
}
public extension CategoriesHolderBasis {
    static func getOrInsert(from: Category, name: String, context: ModelContext) -> SubCategory {
        if let target = from.children.first(where: {$0.name == name } ) {
            target.isLocked = true;
            return target
        }
        else {
            let result = SubCategory(name, parent: from, isLocked: true)
            context.insert(result)
            
            return result
        }
    }
}

public struct AccountControlCategories : CategoriesHolderBasis {
    public init(pay: SubCategory, transfer: SubCategory, audit: SubCategory, initial: SubCategory) {
        self.pay = pay
        self.transfer = transfer
        self.audit = audit
        self.initial = initial
    }
    @MainActor
    public init(context: ModelContext, from: Category?) {
        if let from = from {
            from.isLocked = true
            self.init(
                pay: Self.getOrInsert(from: from, name: "Pay", context: context),
                transfer: Self.getOrInsert(from: from, name: "Transfer", context: context),
                audit: Self.getOrInsert(from: from, name: "Audit", context: context),
                initial: Self.getOrInsert(from: from, name: "Initial", context: context)
            )
        }
        else {
            let parent = Category(Self.name, isLocked: true)
            self.init(
                pay: .init("Pay", parent: parent, isLocked: true),
                transfer: .init("Transfer", parent: parent, isLocked: true),
                audit: .init("Audit", parent: parent, isLocked: true),
                initial: .init("Initial", parent: parent, isLocked: true)
            )
            context.insert(parent)
        }
    }
    
    public static var name: String { "Account Control" }
    
    public let pay: SubCategory;
    public let transfer: SubCategory;
    public let audit: SubCategory;
    public let initial: SubCategory;
}

public struct PaymentsCategories : CategoriesHolderBasis {
    public init(loan: SubCategory, repayment: SubCategory, refund: SubCategory, gift: SubCategory, interest: SubCategory) {
        self.loan = loan
        self.repayment = repayment
        self.refund = refund
        self.gift = gift
        self.interest = interest
    }
    
    @MainActor
    public init(context: ModelContext, from: Category?) {
        if let from = from {
            from.isLocked = true
            self.init(
                loan: Self.getOrInsert(from: from, name: "Loan", context: context),
                repayment: Self.getOrInsert(from: from, name: "Repayment", context: context),
                refund: Self.getOrInsert(from: from, name: "Refund", context: context),
                gift: Self.getOrInsert(from: from, name: "Gift", context: context),
                interest: Self.getOrInsert(from: from, name: "Interest", context: context)
            )
        }
        else {
            let parent =  Category(Self.name, isLocked: true)
            self.init(
                loan: .init("Loan", isLocked: true),
                repayment: .init("Repayment", isLocked: true),
                refund: .init("Refund", isLocked: true),
                gift: .init("Gift", isLocked: true),
                interest: .init("Interest", isLocked: true)
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
    
    public static var name: String { "Payments" }
    
    public let loan: SubCategory;
    public let repayment: SubCategory;
    public let refund: SubCategory;
    
    public let gift: SubCategory;
    public let interest: SubCategory;
}

public struct BillPaymentsCategories : CategoriesHolderBasis {
    public init(bill: SubCategory, sub: SubCategory, utility: SubCategory) {
        self.bill = bill
        self.subscription = sub
        self.utility = utility
    }
    
    @MainActor
    public init(context: ModelContext, from: Category?) {
        if let from = from {
            from.isLocked = true
            self.init(
                bill: Self.getOrInsert(from: from, name: "Bill", context: context),
                sub: Self.getOrInsert(from: from, name: "Subscription", context: context),
                utility: Self.getOrInsert(from: from, name: "Utility", context: context)
            )
        }
        else {
            let parent = Category(Self.name, isLocked: true)
            self.init(
                bill: .init("Bill", isLocked: true),
                sub: .init("Subscription", isLocked: true),
                utility: .init("Utility", isLocked: true)
            )
            
            parent.children = [
                bill,
                subscription,
                utility,
            ]
            context.insert(parent)
        }
    }
    
    public static let name: String = "Bills"
    
    public let bill: SubCategory;
    public let subscription: SubCategory;
    public let utility: SubCategory;
}

/// Provides a lookup for the basic SubCategories that are used by the program.
public struct CategoriesContext {
    @MainActor
    public init(_ context: ModelContext) throws {
        let categories = try context.fetch(FetchDescriptor<Category>())
        
        let acc     = AccountControlCategories(context: context, from: categories.first(where: {$0.name == AccountControlCategories.name } ) )
        let payment = PaymentsCategories      (context: context, from: categories.first(where: {$0.name == PaymentsCategories.name       } ) )
        let bills   = BillPaymentsCategories  (context: context, from: categories.first(where: {$0.name == BillPaymentsCategories.name   } ) )
        
        self.accountControl = acc
        self.payments = payment
        self.bills = bills
    }
    
    public let accountControl: AccountControlCategories;
    public let payments: PaymentsCategories;
    public let bills: BillPaymentsCategories;
}

private struct CategoriesContextKey: EnvironmentKey {
    static var defaultValue: CategoriesContext? {
        nil
    }
}

extension EnvironmentValues {
    public var categoriesContext: CategoriesContext? {
        get { self[CategoriesContextKey.self] }
        set { self[CategoriesContextKey.self] = newValue }
    }
}

//
//  CategoryContext.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import SwiftData
import SwiftUI

public protocol CategoriesHolderBasis {
    init?(context: ModelContext, from: Category?)
    static var name: String { get }
}
public extension CategoriesHolderBasis {
    static func getOrInsert(from: Category, name: String, context: ModelContext) -> SubCategory {
        if let target = from.children?.first(where: {$0.name == name } ) {
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
    public init(pay: SubCategory, transfer: SubCategory, audit: SubCategory) {
        self.pay = pay
        self.transfer = transfer
        self.audit = audit
    }
    public required convenience init?(context: ModelContext, from: Category?) {
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
    
    public static var name: String { "Account Control" }
    
    public let pay: SubCategory;
    public let transfer: SubCategory;
    public let audit: SubCategory;
}

@Observable
public class PaymentsCategories : CategoriesHolderBasis {
    public init(loan: SubCategory, repayment: SubCategory, refund: SubCategory, gift: SubCategory, interest: SubCategory) {
        self.loan = loan
        self.repayment = repayment
        self.refund = refund
        self.gift = gift
        self.interest = interest
    }
    public required convenience init?(context: ModelContext, from: Category?) {
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
    
    public static var name: String { "Payments" }
    
    public let loan: SubCategory;
    public let repayment: SubCategory;
    public let refund: SubCategory;
    
    public let gift: SubCategory;
    public let interest: SubCategory;
}

@Observable
public class BillPaymentsCategories : CategoriesHolderBasis{
    public init(bill: SubCategory, sub: SubCategory, utility: SubCategory) {
        self.bill = bill
        self.subscription = sub
        self.utility = utility
    }
    public required convenience init?(context: ModelContext, from: Category?) {
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
    
    public static let name: String = "Bills"
    
    public let bill: SubCategory;
    public let subscription: SubCategory;
    public let utility: SubCategory;
}

/// Provides a lookup for the basic SubCategories that are used by the program.
@Observable
public class CategoriesContext {
    public init?(_ context: ModelContext) {
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

private struct CategoriesContextKey: EnvironmentKey {
    static let defaultValue: CategoriesContext? = nil
}

extension EnvironmentValues {
    public var categoriesContext: CategoriesContext? {
        get { self[CategoriesContextKey.self] }
        set { self[CategoriesContextKey.self] = newValue }
    }
}

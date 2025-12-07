//
//  CategoryContext.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import CoreData
import SwiftUI

/// Provides a lookup for the basic SubCategories that are used by the program.
public struct CategoriesContext {
    @MainActor
    public init(cx: NSManagedObjectContext) throws {
        let categories = try cx.fetch(Category.fetchRequest());
        var tree = try ElementLocator(data: categories);
        
        self.income = tree.getOrInsert(name: "Income");
        self.transfers = tree.getOrInsert(name: "Transfers");
        self.adjustments = tree.getOrInsert(name: "Adjustments");
        self.loan = tree.getOrInsert(name: "Loan");
        self.bills = tree.getOrInsert(name: "Bills");
        
        self.income.isLocked = true
        self.transfers.isLocked = true
        self.adjustments.isLocked = true
        self.loan.isLocked = true
        self.bills.isLocked = true
    }
    
    public let income: Category;
    public let transfers: Category;
    public let adjustments: Category;
    public let loan: Category;
    public let bills: Category;
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

//
//  CategoryContext.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import CoreData
import SwiftUI
import os

/// Provides a lookup for the basic SubCategories that are used by the program.
public struct CategoriesContext {
    @MainActor
    public init(store: NSPersistentContainer, logger: Logger) async throws {
        let ids: [String : NSManagedObjectID] = try await Task(priority: .background) {
            let cx = store.newBackgroundContext();
            logger.info("Determining categories context on background thread.")
            
            logger.debug("Fetching current accounts that match the required names.");
            
            // See what we already have, and what we need to add.
            let query = Category.fetchRequest();
            query.predicate = NSPredicate(format: "internalName IN %@", Self.requiredCategories);
            let fetched: [Category];
            do {
                fetched = try cx.fetch(query);
                logger.debug("Fetched \(fetched.count) categories");
            }
            catch let e {
                logger.error("Unable to fetch the categories: \(e)");
                throw e;
            }
            
            var result: [String : NSManagedObjectID] = [:];
            for account in fetched {
                result[account.name] = account.objectID;
            }
            
            logger.info("Got \(result.count) out of \(Self.requiredCategories.count) required categories.");
            
            guard result.count != Self.requiredCategories.count else { //We have a match
                return result;
            }
            
            //Find what is missing.
            for name in Self.requiredCategories {
                if result[name] == nil {
                    //Insert
                    let cat = Category(context: cx);
                    cat.name = name;
                    cat.id = UUID();
                    
                    result[name] = cat.objectID;
                }
            }
            
            logger.debug("Inserted new categories. Saving.");
            
            do {
                try cx.save()
            } catch let e {
                logger.error("Unable to save: \(e)")
                throw e;
            }
            
            return result;
        }.value;
        
        // Now we just match IDs to instances.
        let cx = store.viewContext;
        
        self.income = cx.object(with: ids["Income"]!) as! Category;
        self.transfers = cx.object(with: ids["Transfers"]!) as! Category;
        self.adjustments = cx.object(with: ids["Adjustments"]!) as! Category;
        self.loan = cx.object(with: ids["Loan"]!) as! Category;
        self.bills = cx.object(with: ids["Bills"]!) as! Category;
    }
    
    public static let requiredCategories: [String] = [
        "Income",
        "Transfers",
        "Adjustments",
        "Loan",
        "Bills"
    ]
    
    @MainActor public var income: Category;
    @MainActor public var transfers: Category;
    @MainActor public var adjustments: Category;
    @MainActor public var loan: Category;
    @MainActor public var bills: Category;
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

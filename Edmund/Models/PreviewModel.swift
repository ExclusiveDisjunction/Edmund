//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData

@MainActor
class ModelController {
    static let schema: Schema = {
        return Schema(
            [
                LedgerEntry.self,
                Account.self,
                SubAccount.self,
                Category.self,
                SubCategory.self,
                Bill.self,
                Utility.self
            ]
        )
    }()
    
    static let previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            var result = try ModelContainer(for: schema, configurations: [ configuration ])
            
            //Inserting mock stuff
            let accounts = Account.exampleAccounts
            for account in accounts {
                result.mainContext.insert(account)
            }
            let categories = Category.exampleCategories;
            for category in categories {
                result.mainContext.insert(category)
            }

            //We make our own manual LedgerEntry
            let ledger: [LedgerEntry] = [ ("A", 0, 10, accounts[0].children[1], categories[0].children[1]), ("B", 0, 10, accounts[0].children[2], categories[0].children[1]), ("C", 10, 4, accounts[1].children[1], categories[0].children[1])].reduce(into: []) {
                $0.append(
                    LedgerEntry(
                        memo: $1.0,
                        credit: $1.1,
                        debit: $1.2,
                        date: Date.now,
                        added_on: Date.now,
                        location: "Bank",
                        category: $1.4,
                        account: $1.3)
                )
            }
            
            for entry in ledger {
                result.mainContext.insert(entry);
            }
            
            let bills = Bill.exampleBills;
            for bill in bills {
                result.mainContext.insert(bill)
            }
            let utilities = Utility.exampleUtilities;
            for utility in utilities {
                result.mainContext.insert(utility)
            }
            
            return result
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    static let sharedModelContainer: ModelContainer = {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [ configuration ])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

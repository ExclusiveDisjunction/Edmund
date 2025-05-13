//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData

@MainActor
public class Containers {
    public static let schema: Schema = {
        return Schema(
            [
                LedgerEntry.self,
                Account.self,
                SubAccount.self,
                Category.self,
                SubCategory.self,
                Bill.self,
                Utility.self,
                UtilityEntry.self,
            ]
        )
    }()
    
    public static let debugContainer: ModelContainer = {
        let configuration = ModelConfiguration("debug", schema: schema, isStoredInMemoryOnly: true)
        
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
            let ledger = LedgerEntry.exampleEntries(acc: accounts, cat: categories)
            
            for entry in ledger {
                result.mainContext.insert(entry);
            }
            
            let bills = Bill.exampleBills;
            for bill in bills {
                result.mainContext.insert(bill)
            }
            
            let utilities = Utility.exampleUtility;
            for utility in utilities {
                result.mainContext.insert(utility)
            }
            
            return result
        } catch {
            fatalError("Could not create Debug ModelContainer: \(error)")
        }
    }()
    
    public static let transactionsWithSpreadContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration("example", schema: schema, isStoredInMemoryOnly: true)
            
            var result = try ModelContainer(for: schema, configurations: [ configuration ])
            
            let account = SubAccount("", parent: .init(""))
            let category = SubCategory("", parent: .init(""))
            
            result.mainContext.insert(account)
            result.mainContext.insert(category)
            
            let transactions: [LedgerEntry] = [
                .init(name: "", credit: 100, debit: 0, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 100, debit: 0, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 0, debit: 200, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
                
                .init(name: "", credit: 0, debit: 100, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 0, debit: 100, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 400, debit: 0, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 0, debit: 100, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
                
                .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 0, debit: 500, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
                
                .init(name: "", credit: 0, debit: 300, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 0, debit: 300, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 100, debit: 0, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
                .init(name: "", credit: 0, debit: 300, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            ];
            
            for trans in transactions {
                result.mainContext.insert(trans)
            }
            
            return result;
        }
        catch {
            fatalError("Could not create Example ModelContainer: \(error)")
        }
    }()
    
    public static let container: ModelContainer = {
        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            
            return try ModelContainer(for: schema, configurations: [configuration ] )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

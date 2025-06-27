//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData

/// A collection of various tools used for SwiftData containers.
public struct Containers {
    /// The schema used by the containers.
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
                HourlyJob.self,
                SalariedJob.self,
                BudgetInstance.self,
                AmountDevotion.self,
                PercentDevotion.self,
                RemainderDevotion.self
            ]
        )
    }()
    
    /// A container that contains temporary, simple data used for showcasing.
    @MainActor
    public static let debugContainer: ModelContainer = {
        let configuration = ModelConfiguration("debug", schema: schema, isStoredInMemoryOnly: true)
        
        do {
            var result = try ModelContainer(for: schema, configurations: [ configuration ])
            if result.mainContext.undoManager == nil {
                result.mainContext.undoManager = UndoManager()
            }
            
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
            
            result.mainContext.insert(HourlyJob(company: "Winn Dixie", position: "Customer Service Associate", hourlyRate: 13.75, avgHours: 30, taxRate: 0.15))
            
            result.mainContext.insert(SalariedJob(company: "Winn Dixie", position: "Customer Service Manager", grossAmount: 850, taxRate: 0.25))
            
            let accPay = accounts.findPair("Checking", "Pay")!
            let accBills = accounts.findPair("Checking", "Bills")!
            let accGroc = accounts.findPair("Checking", "Groceries")!
            let personal = accounts.findPair("Checking", "Personal")!
            let taxes = accounts.findPair("Checking", "Taxes")!
            let main = accounts.findPair("Savings", "Main")!
            
            result.mainContext.insert(BudgetInstance.exampleBudget(pay: accPay, bills: accBills, groceries: accGroc, personal: personal, taxes: taxes, main: main))
            
            
            return result
        } catch {
            fatalError("Could not create Debug ModelContainer: \(error)")
        }
    }()
    
    /// A model container with just transactions. it shows a spread with amounts & dates so that the UI elements can be tested.
    @MainActor
    public static let transactionsWithSpreadContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration("example", schema: schema, isStoredInMemoryOnly: true)
            
            var result = try ModelContainer(for: schema, configurations: [ configuration ])
            if result.mainContext.undoManager == nil {
                result.mainContext.undoManager = UndoManager()
            }
            
            let account = SubAccount("", parent: .init(""))
            let category = SubCategory("", parent: .init("", children: []))
            
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
    
    /// The main container used by the app. This stores the data for the app in non-debug based contexts. 
    @MainActor
    public static let container: ModelContainer = {
        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            
            let result = try ModelContainer(for: schema, configurations: [configuration ] )
            if result.mainContext.undoManager == nil {
                result.mainContext.undoManager = UndoManager()
            }
            
            return result;
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

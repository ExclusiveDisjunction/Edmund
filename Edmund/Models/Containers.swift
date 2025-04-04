//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData

enum ContainerNames: Equatable, Identifiable, Hashable, Codable {
    case debug
    case personal
    case global
    case named(String)
    
    var id: Self { self }
    
    var name: String {
        switch self {
            case .debug : "Debug"
            case .personal: "Personal"
            case .global: "Global"
            case .named(let name): name
        }
    }
}

@MainActor
class Containers {
    static let schema: Schema = {
        return Schema(
            [
                LedgerEntry.self,
                Account.self,
                SubAccount.self,
                Category.self,
                SubCategory.self,
                Bill.self,
                UtilityEntry.self,
                UtilityBridge.self
            ]
        )
    }()
    
    static let debugContainer: ModelContainer = {
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
            
            return result
        } catch {
            fatalError("Could not create Debug ModelContainer: \(error)")
        }
    }()
    static let personalContainer: ModelContainer = {
        do {
            return try getNamedContainer("personal")
        } catch {
            fatalError("Could not create Personal ModelContainer: \(error)")
        }
    }()
    static let globalContainer: ModelContainer = {
        let schema = Schema([ Profile.self ])
        let configuration = ModelConfiguration("global", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
        
        do {
            return try ModelContainer(for: schema, configurations: [ configuration ])
        } catch {
            fatalError("Could not create Global ModelContainer: \(error)")
        }
    }()
    
    static var openContainers: [Profile.ID: ModelContainer] = [:]
    
    static var defaultContainer: (ModelContainer, ContainerNames) {
        #if DEBUG
        (debugContainer, .debug)
        #else
        (personalContainer, .personal)
        #endif
    }
    static var defaultContainerName: ContainerNames {
#if DEBUG
        .debug
#else
        .personal
#endif
    }
    
    static func getNamedContainer(_ name: String) throws -> ModelContainer {
        if name == ContainerNames.debug.name {
#if DEBUG
            return debugContainer
#else
            throw NSError(domain: "Attemted to get debug container in non debug build", code: 0, userInfo: nil)
#endif
        }
        else if name == ContainerNames.personal.name {
            return personalContainer
        }
        else {
            if let result = openContainers[name]{
                return result
            }
            else {
                let configuration = ModelConfiguration(name, schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
                
                let result = try ModelContainer(for: schema, configurations: [configuration ] )
                openContainers[name] = result
                
                return result
            }
        }
    }
    static func getContainer(_ target: ContainerNames) throws -> ModelContainer {
        switch target {
            case .debug:
                #if DEBUG
                return debugContainer
                #else
                throw NSError(domain: "Attemted to get debug container in non debug build", code: 0, userInfo: nil)
                #endif
            case .global: return globalContainer
            case .personal: return personalContainer
            case .named(let name): return try getNamedContainer(name)
        }
    }
}

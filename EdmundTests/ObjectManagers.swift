//
//  ChildrenUpdater.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/7/25.
//

import CoreData
import Edmund
import Testing
import os

struct ElementLocatorTester {
    @MainActor
    @Test
    func testElementLocator() async throws {
        let container = DataStack.shared.emptyDebugContainer;
        
        try await container.viewContext.perform {
            var locator = try ElementLocator<Edmund.Category>(data: []);
            
            let cx = container.viewContext;
            do {
                let a = locator.getOrInsert(name: "a", cx: cx);
                a.id = UUID();
                let b = locator.getOrInsert(name: "b", cx: cx);
                b.id = UUID();
                let c = locator.getOrInsert(name: "c", cx: cx);
                c.id = UUID();
            }
            
            try cx.save();
            
            //Now to see if the fetch worked.
            let predicate = Edmund.Category.fetchRequest();
            predicate.predicate = NSPredicate(fromMetadataQueryString: "internalName == 'a' || internalName == 'b' || internalName == 'c'");
            predicate.sortDescriptors = [NSSortDescriptor(keyPath: \Edmund.Category.internalName, ascending: true)];
            
            let fetched: [Edmund.Category] = try cx.fetch(predicate);
            
            #expect(fetched.map { $0.name } == ["a", "b", "c"] )
        }
    }
    
    @MainActor
    @Test
    func testAccountLocator() async throws {
        let container = DataStack.shared.emptyDebugContainer;
        
        try await container.viewContext.perform {
            let cx = container.viewContext;
            
            var locator = try AccountLocator(fetch: cx);
            
            do {
                locator.getOrInsertAccount(name: "a", cx: cx).id = UUID();
                locator.getOrInsertAccount(name: "b", cx: cx).id = UUID();
                locator.getOrInsertAccount(name: "c", cx: cx).id = UUID();
            }
            
            try cx.save();
            
            do {
                locator.getOrInsertEnvolope(name: "a", accountName: "a", cx: cx).id = UUID();
                locator.getOrInsertEnvolope(name: "b", accountName: "a", cx: cx).id = UUID();
                
                locator.getOrInsertEnvolope(name: "a", accountName: "b", cx: cx).id = UUID();
                locator.getOrInsertEnvolope(name: "b", accountName: "b", cx: cx).id = UUID();
                
                locator.getOrInsertEnvolope(name: "a", accountName: "c", cx: cx).id = UUID();
                locator.getOrInsertEnvolope(name: "b", accountName: "c", cx: cx).id = UUID();
            }
            
            try cx.save();
            
            let predicate = Edmund.Account.fetchRequest();
            predicate.sortDescriptors = [NSSortDescriptor(keyPath: \Account.internalName, ascending: true)];
            
            let fetch: [Account] = try cx.fetch(predicate);
            
            let transformed: [String : [String]] = Dictionary(uniqueKeysWithValues: fetch.map { account in
                (account.name, Array(account.envolopes).map { $0.name }.sorted(using: KeyPathComparator(\String.self)))
            })
            
            let expected = [
                "a" : ["a", "b"],
                "b" : ["a", "b"],
                "c" : ["a", "b"]
            ];
            
            #expect(transformed == expected)
        }
    }
    
    @MainActor
    @Test
    func testCategoriesContext() async throws {
        let container = DataStack.shared.emptyDebugContainer;
        let logger = Logger(subsystem: "com.exdisj.Edmund", category: "Testing");
        
        let _ = try await CategoriesContext(store: container, logger: logger);
        
        let fetch = Edmund.Category.fetchRequest();
        fetch.predicate = NSPredicate(format: "internalName IN %@", CategoriesContext.requiredCategories);
        fetch.sortDescriptors = [NSSortDescriptor(keyPath: \Edmund.Category.internalName, ascending: true)];
        
        let categories = try container.viewContext.fetch(fetch);
        
        #expect(categories.map { $0.name } == CategoriesContext.requiredCategories.sorted() )
    }
}

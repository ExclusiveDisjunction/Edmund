//
//  Containers.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/7/25.
//

import CoreData
import Edmund
import Testing

struct ContainerUnitTests {
    @Test
    func loadPersistentContainer() async throws {
        let container = DataStack.shared.persistentContainer;
        
        // Fetch the count of accounts just to try it.
        try await container.viewContext.perform {
            let request = Account.fetchRequest();
            let count = try container.viewContext.count(for: request)
            print("The count of accounts is \(count) in the persistent container.");
            
            //The test passes if no error throws.
        }
    }
    
    @Test
    func loadDebugStore() async throws {
        let container = DataStack.shared.debugContainer;
        
        // Fetch the count of accounts just to try it.
        try await container.viewContext.perform {
            let request = Account.fetchRequest();
            let count = try container.viewContext.count(for: request)
            print("The count of accounts is \(count) in the persistent container.");
            
            //The test passes if no error throws.
        }
    }
}

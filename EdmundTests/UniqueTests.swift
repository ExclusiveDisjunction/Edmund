//
//  UniqueTests.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/5/25.
//

import Testing
import SwiftData
import EdmundCore

struct UniqueTests {
    @Test
    @MainActor
    func testAccounts() throws {
        let container = try Containers.uniqueDebugContainer()
        
        let data = try container.context.fetch(FetchDescriptor<Account>());
        let set = Set<Account.ID>(data.lazy.map { $0.id } )
        #expect(set.count == data.count)
    }
    
    @Test
    @MainActor
    func testSubAccounts() throws {
        let container = try Containers.uniqueDebugContainer()
        
        let data = try container.context.fetch(FetchDescriptor<SubAccount>());
        let set = Set(data.lazy.map { $0.id } )
        #expect(set.count == data.count)
    }
    
    @Test
    @MainActor
    func testCategories() throws {
        let container = try Containers.uniqueDebugContainer()
        
        let data = try container.context.fetch(FetchDescriptor<EdmundCore.Category>());
        let set = Set(data.lazy.map { $0.id } )
        #expect(set.count == data.count)
    }
    
    @Test
    @MainActor
    func testSubCategories() throws {
        let container = try Containers.uniqueDebugContainer()
        
        let data = try container.context.fetch(FetchDescriptor<SubCategory>());
        let set = Set(data.lazy.map { $0.id } )
        #expect(set.count == data.count)
    }
    
    @Test
    @MainActor
    func testBills() throws {
        let container = try Containers.uniqueDebugContainer()
        
        let bills = try container.context.fetch(FetchDescriptor<Bill>());
        let utilities = try container.context.fetch(FetchDescriptor<Utility>());
        let all = bills.map { $0.id } + utilities.map { $0.id };
        
        let set = Set(all)
        #expect(set.count == (bills.count + utilities.count))
    }
    
    @Test
    @MainActor
    func testJobs() throws {
        let container = try Containers.uniqueDebugContainer()
        
        let hourly = try container.context.fetch(FetchDescriptor<HourlyJob>());
        let salaried = try container.context.fetch(FetchDescriptor<SalariedJob>());
        
        let all = hourly.map { $0.id } + salaried.map { $0.id };
        
        let set = Set(all)
        #expect(set.count == (hourly.count + salaried.count))
    }
    
    @Test
    @MainActor
    func testMainDebugContainer() throws {
        let _ = try Containers.debugContainer()
    }
}

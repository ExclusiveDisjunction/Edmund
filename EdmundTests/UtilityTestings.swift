//
//  UtilityTestings.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/21/25.
//

import EdmundCore
import Testing
import SwiftData

struct UtilityTesting {
    @MainActor
    private func makeContext() async throws -> (Container, UniqueEngine, Utility) {
        let container = try Containers.emptyMemoryContainer();
        let unique = UniqueEngine();
        let entry = Utility("Testing Bill", amounts: [0, 0, 0, 0], company: "Testing", start: .now)
        container.context.insert(entry)
        
        #expect(await unique.reserveId(key: Utility.objId, id: entry.id));
        
        return (container, unique, entry)
    }
    
    @MainActor
    @Test
    func testSameSizeUpdate() async throws {
        let (_, unique, utility) = try await makeContext()
        let snapshot = utility.makeSnapshot();
        
        snapshot.points.forEach { $0.amount.rawValue = 1 };
        let oldCount = utility.points.count;
        try await utility.update(snapshot, unique: unique);
        
        #expect(utility.points.count == oldCount)
        for point in utility.points {
            #expect(point == 1);
        }
    }
    
    @MainActor
    @Test
    func testLargerSizeUpdate() async throws {
        let (_, unique, utility) = try await makeContext()
        
        let snapshot = utility.makeSnapshot();
        
        snapshot.points.forEach { $0.amount.rawValue = 1 };
        snapshot.points.append(.init(amount: .init(rawValue: 1), date: .now))
        let oldCount = utility.points.count;
        try await utility.update(snapshot, unique: unique);
        
        #expect(utility.points.count == oldCount + 1)
        for point in utility.points {
            #expect(point == 1);
        }
    }
    
    @MainActor
    @Test
    func testSmallerSizeUpdate() async throws {
        let (_, unique, utility) = try await makeContext()
        
        let snapshot = utility.makeSnapshot();
        
        snapshot.points.forEach { $0.amount.rawValue = 1 };
        snapshot.points.removeLast(2);
        
        let oldCount = utility.points.count;
        try await utility.update(snapshot, unique: unique);
        
        #expect(utility.points.count == oldCount - 2)
        for point in utility.points {
            #expect(point == 1);
        }
    }
}

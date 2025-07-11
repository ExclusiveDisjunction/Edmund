//
//  HelpTester.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/11/25.
//

import Testing
import Edmund
import Foundation

struct HelpTester {
    private func loadEngine(debug: Bool) async -> (HelpEngine, Bool) {
        let engine = HelpEngine()
        
        if debug {
            guard let url = Bundle.main.url(forResource: "HelpEngineTest", withExtension: nil) else {
                return (engine, false)
            }
            
            return (engine, await HelpEngine.walkDirectory(engine: engine, baseURL: url))
        }
        else {
            return (engine, await HelpEngine.walkDirectory(engine: engine))
        }
    }
    
    @Test
    func testStandardWalking() async {
        let (_, result) = await loadEngine(debug: false)
        
        #expect(result)
    }
    
    @Test
    func testDebugWalking() async {
        let (_, result) = await loadEngine(debug: true)
        
        #expect(result)
    }
    
    @Test
    func testTopicLoading() async {
        let (engine, result) = await loadEngine(debug: true)
        
        #expect(result)
        
        await #expect(throws: TopicFetchError.self) {
            let _ = try await engine.getTopic(id: .init(rawValue: "topic1"))
            let _ = try await engine.getTopic(id: .init(rawValue: "topic2"))
            let _ = try await engine.getTopic(id: .init(rawValue: "topic3"))
        }
        
        await #expect(throws: TopicFetchError.self) {
            let _ = try await engine.getTopic(id: .init(rawValue: "Group1/topic1"))
            let _ = try await engine.getTopic(id: .init(rawValue: "Group2/topic1"))
        }
    }
    
    @Test
    func testGroupLoading() async throws {
        let (engine, result) = await loadEngine(debug: true)
        
        #expect(result)
     
        let root: [LoadedHelpResource] = try await engine.getTree()
        let a: LoadedHelpGroup         = try await engine.getGroup(id: .init(rawValue: "Group1"))
        let b: LoadedHelpGroup         = try await engine.getGroup(id: .init(rawValue: "Group2"))
        let c: LoadedHelpGroup         = try await engine.getGroup(id: .init(rawValue: "Group3"))
        let d: LoadedHelpGroup         = try await engine.getGroup(id: .init(rawValue: "topic1"))
        
        #expect(a.children.count == 1)
        #expect(b.children.count == 1)
        #expect(c.children.isEmpty)
        #expect(d.children.isEmpty)
        
        #expect(root.count == 7)
    }
}

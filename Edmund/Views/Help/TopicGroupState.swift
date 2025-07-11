//
//  TopicGroupState.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/11/25.
//

import Foundation
import SwiftUI

@MainActor
@propertyWrapper
public struct TopicState : DynamicProperty {
    public init(_ id: String) {
        self.init(HelpResourceID(rawValue: id))
    }
    public init(_ id: HelpResourceID) {
        let data = TopicLoadHandle(id: id)
        
        self.data = data
        let engine = self.helpEngine
        
        // Starts the request to load the data
        Task {
            await engine.getTopic(deposit: data)
        }
    }
    
    @Environment(\.helpEngine) private var helpEngine;
    private var data: TopicLoadHandle;
    
    public var wrappedValue: TopicLoadHandle {
        data
    }
}

@MainActor
@propertyWrapper
public struct TopicGroupState : DynamicProperty {
    public init(_ id: String) {
        self.init(HelpResourceID(rawValue: id))
    }
    public init(_ id: HelpResourceID) {
        self.data = .init(id: id)
    }
    
    @Environment(\.helpEngine) private var helpEngine;
    @Bindable private var data: TopicLoadHandle;
    
    public var wrappedValue: TopicLoadHandle {
        data
    }
    
}

struct TopicGroupStateTester : View {
    @TopicState("Help/Documentation/Change Log.md") private var group;
    
    var body: some View {
        Text(String(describing: group.status))
            .frame(width: 200, height: 100)
    }
}

#Preview {
    let engine = HelpEngine()
    let _ = Task {
        await HelpEngine.walkDirectory(engine: engine)
    }
    
    TopicGroupStateTester()
        .padding()
        .environment(\.helpEngine, engine)
}

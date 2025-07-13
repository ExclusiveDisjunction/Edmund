//
//  TopicGroupState.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/11/25.
//

import Foundation
import SwiftUI

/// A property wrapper that is used to load a help topic in the background.
@MainActor
@propertyWrapper
public struct TopicGroupState : DynamicProperty {
    public init(_ id: String, lazy: Bool = false) {
        self.init(HelpResourceID(rawValue: id), lazy: lazy)
    }
    public init(_ id: HelpResourceID, lazy: Bool = false) {
        self.data = GroupLoadHandle(id: id)
        
        // Starts the request to load the data
        if !lazy {
            fetch()
        }
    }
    
    @Environment(\.helpEngine) private var helpEngine;
    private var data: GroupLoadHandle;
    
    private func fetch() {
        let engine = self.helpEngine
        let data = self.data;
        Task {
            await engine.getGroup(deposit: data)
        }
    }
    public func refresh() {
        self.fetch()
    }
    
    public var wrappedValue: GroupLoadHandle {
        data
    }
}

struct TopicGroupStateTester : View {
    @TopicGroupState("Documentation") private var group;
    
    var body: some View {
        VStack {
            Button("Refresh", action: _group.refresh)
            
            Text(String(describing: group.status))
                .frame(width: 200, height: 100)
        }
    }
}

#Preview {
    let engine = HelpEngine()
    let _ = Task {
        await HelpEngine.walkDirectory(engine: engine)
    }
    
    HStack {
        TopicGroupStateTester()
            .padding()
            .environment(\.helpEngine, engine)
    }
}

//
//  WholeHelpTreeState.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI

/// A property wrapper that is used to load the help tree in the background.
@MainActor
@propertyWrapper
public struct WholeHelpTreeState : DynamicProperty {
    public init(lazy: Bool = false) {
        self.data = WholeTreeLoadHandle();
        
        // Starts the request to load the data
        if !lazy {
            fetch()
        }
    }
    
    @Environment(\.helpEngine) private var helpEngine;
    private var data: WholeTreeLoadHandle;
    
    private func fetch() {
        let engine = self.helpEngine
        let data = self.data;
        Task {
            await engine.getTree(deposit: data)
        }
    }
    public func refresh() {
        self.fetch()
    }
    
    public var wrappedValue: WholeTreeLoadHandle {
        data
    }
}

struct WholeHelpTreeStateTester : View {
    @WholeHelpTreeState private var group;
    
    var body: some View {
        VStack {
            Button("Refresh", action: _group.refresh)
            
            Text(String(describing: group.status))
                .frame(width: 200, height: 100)
            
        }
    }
}

#Preview {
    WholeHelpTreeStateTester()
        .padding()
}

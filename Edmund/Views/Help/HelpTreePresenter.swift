//
//  HelpTreePresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/13/25.
//

import SwiftUI

struct HelpTreePresenter : View {
    
    @Environment(\.helpEngine) private var helpEngine;
    @Bindable private var handle: GroupLoadHandle = .init(id: .init())
    @State private var oldTask: Task<Void, Never>? = nil;
    
    private func refresh() {
        if let task = oldTask {
            task.cancel()
        }
        
        oldTask = Task {
            await helpEngine.getTree(deposit: handle)
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        VStack {
            Spacer()
            
            Text("Loading")
            ProgressView()
                .progressViewStyle(.linear)
            
            Button(action: refresh) {
                Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
            }
            
            Spacer()
        }
    }
    
    var body: some View {
        switch handle.status {
            case .loading:
                statusView
                    .onAppear {
                        refresh()
                    }
            case .error(let e):
                VStack {
                    Spacer()
                    
                    GroupFetchErrorPresenter(e: e)
                        .padding()
                    
                    Spacer()
                }
            case .loaded(let v):
                LoadedHelpGroupPresenter(data: v, title: NSLocalizedString("Edmund Help", comment: ""))
        }
    }
}

#Preview {
    let engine = HelpEngine()
    let _ = Task {
        await engine.walkDirectory()
    }
    
    HelpTreePresenter()
        .environment(\.helpEngine, engine)
}

//
//  TopicGroupPresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI

struct TopicGroupPresenter : View, HelpPresenterView {
    init(_ key: HelpResourceID) {
        self.key = key
    }
    
    private let key: HelpResourceID;
    
    private func refresh(_ engine: HelpEngine, _ data: GroupLoadHandle) async {
        await engine.getGroup(deposit: data)
    }
    
    @ViewBuilder
    private func errorView(_ e: GroupFetchError) -> some View {
        switch e {
            case .engineLoading:
                Text("The help system is not done loading. Please wait, and refresh.")
                Text("If this is a common or persistent issue, please report it.")
                
            case .isATopic:
                Text("Edmund expected a group of topics, but got a single topic instead.")
                Text("This is not an issue caused by you, but the developer.")
                Text("Please report this issue.")
            case .notFound:
                Text("Edmund could not find that topic.")
                Text("This is not an issue caused by you, but the developer.")
                Text("Please report this issue.")
        }
    }
    
    @ViewBuilder
    private func loadedView(_ v: LoadedHelpGroup) -> some View {
        NavigationSplitView {
            
        } detail: {
            
        }
    }
    
    var body: some View {
        HelpResourcePresenter(key, refresh: refresh, error: errorView, content: loadedView)
    }
}

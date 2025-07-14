//
//  TopicPresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI
import MarkdownUI

struct TopicPresenter : View, HelpPresenterView {
    init(_ key: HelpResourceID) {
        self.key = key
    }
    
    private let key: HelpResourceID;
    
    private func refresh(_ engine: HelpEngine, _ data: TopicLoadHandle) async {
        await engine.getTopic(deposit: data)
    }
    
    @ViewBuilder
    private func errorView(_ e: TopicFetchError) -> some View {
        switch e {
            case .engineLoading:
                Text("The help system is not done loading. Please wait, and refresh.")
                Text("If this is a common or persistent issue, please report it.")
                
            case .fileReadError(let ie):
                Text("Edmund was not able to obtain the guide's contents.")
                Text("Error description: \(ie)")
                
            case .isAGroup:
                Text("Edmund expected a single topic, but got a group of topics instead.")
                Text("This is not an issue caused by you, but the developer.")
                Text("Please report this issue.")
            case .notFound:
                Text("Edmund could not find that topic.")
                Text("This is not an issue caused by you, but the developer.")
                Text("Please report this issue.")
        }
    }
    
    @ViewBuilder
    private func loadedView(_ v: LoadedHelpTopic) -> some View {
        ScrollView {
            Markdown(v.content)
                .background(
                    RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                        .fill(.background.secondary)
                )
        }
    }
    
    var body: some View {
        HelpResourcePresenter(key, refresh: refresh, header: { id in
            HStack {
                Text(id.name)
                    .font(.title)
                Spacer()
            }
            
            HStack {
                Text("Topic")
                    .font(.subheadline)
                    .italic()
                
                Spacer()
            }
        }, error: errorView, content: loadedView)
    }
}

#Preview {
    let engine = HelpEngine()
    let _ = Task {
        await engine.walkDirectory()
    }
    
    
    TopicPresenter(.init(rawValue: "Help/Introduction.md"))
        .environment(\.helpEngine, engine)
        .frame(width: 400, height: 300)
}

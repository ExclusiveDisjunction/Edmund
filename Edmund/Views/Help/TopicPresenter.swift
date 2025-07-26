//
//  TopicPresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI
import MarkdownUI

struct TopicContentPresenter : View {
    let over: LoadedHelpTopic;
    
    var body: some View {
        ScrollView {
            Markdown(over.content)
                .background(
                    RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                        .fill(.background.secondary)
                )
        }
    }
}

struct TopicPagePresenter : View {
    let over: LoadedHelpTopic;
    
    var body: some View {
        VStack {
            HStack {
                Text(over.name)
                    .font(.title)
                Spacer()
            }
            
            HStack {
                Text("Topic")
                    .font(.subheadline)
                    .italic()
                
                Spacer()
            }
            
            TopicContentPresenter(over: over)
        }
    }
}

/*
 public struct UnloadedTopicPagePresenter : View {
 public init(over: TopicRequest) {
 self.over = over
 self.handle = .init(id: over.id)
 }
 public let over: TopicRequest;
 
 @Environment(\.helpEngine) private var helpEngine;
 @Bindable private var handle: TopicLoadHandle;
 @State private var oldTask: Task<Void, Never>? = nil;
 
 @ViewBuilder
 private var loading: some View {
 Spacer()
 
 Text("Loading")
 ProgressView()
 .progressViewStyle(.linear)
 
 Spacer()
 }
 
 public var body: some View {
 switch handle.status {
 case .loading:
 loading
 .task {
 await helpEngine.getTopic(deposit: handle)
 }
 case .error(let e):
 TopicErrorView(e: e)
 case .loaded(let t):
 TopicPagePresenter(over: t)
 }
 }
 }
 */

struct TopicErrorView : View {
    let e: TopicFetchError
    
    var body: some View {
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
}

struct TopicPresenter : View, HelpPresenterView {
    init(_ key: HelpResourceID) {
        self.key = key
    }
    
    private let key: HelpResourceID;
    
    private func refresh(_ engine: HelpEngine, _ data: TopicLoadHandle) async {
        await engine.getTopic(deposit: data)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(key.name)
                    .font(.title)
                Spacer()
            }
            
            HStack {
                Text("Topic")
                    .font(.subheadline)
                    .italic()
                
                Spacer()
            }
            
            HelpResourcePresenter(key, refresh: refresh, error: TopicErrorView.init, content: TopicContentPresenter.init)
        }.padding()
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

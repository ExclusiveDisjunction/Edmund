//
//  TopicPresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI
import MarkdownUI

struct HelpResourcePresenter<T, E, HeaderView, ErrorView, ContentView> : View where T: HelpResourceCore, E: Error, E: Sendable, HeaderView: View, ErrorView: View, ContentView: View {
    init(_ key: HelpResourceID, refresh: @escaping (HelpEngine, ResourceLoadHandle<T, E>) async -> Void, @ViewBuilder header: @escaping (HelpResourceID) -> HeaderView, @ViewBuilder error: @escaping (E) -> ErrorView, @ViewBuilder content: @escaping (T) -> ContentView) {
        self.data = .init(id: key)
        
        self.refresh = refresh
        self.header = header
        self.error = error
        self.content = content
    }
    
    @Environment(\.helpEngine) private var helpEngine;
    @Environment(\.dismiss) private var dismiss;
    
    private let refresh: (HelpEngine, ResourceLoadHandle<T, E>) async -> Void;
    private let header: (HelpResourceID) -> HeaderView;
    private let error: (E) -> ErrorView;
    private let content: (T) -> ContentView;
    
    @Bindable private var data: ResourceLoadHandle<T, E>;
    @State private var task: Task<Void, Never>? = nil;
    
    private func performRefresh() {
        if let oldTask = task {
            oldTask.cancel()
        }
        
        let engine = helpEngine;
        let handle = data;
        
        task = Task {
            await refresh(engine, handle)
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        Spacer()
        
        Text("Loading")
        ProgressView()
            .progressViewStyle(.linear)
        
        Button(action: performRefresh) {
            Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
        }
        
        Spacer()
    }
    
    var body: some View {
        VStack {
            header(data.id)
            
            switch data.status {
                case .loading:
                    statusView
                case .error(let e):
                    Spacer()
                    
                    error(e)
                    Button("Refresh", action: performRefresh)
                    
                    Spacer()
                case .loaded(let v):
                    content(v)
            }
            
            HStack {
                Spacer()
                
                Button("Ok", action: { dismiss() })
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
            .onAppear {
                performRefresh()
            }
    }
}
extension HelpResourcePresenter where HeaderView == EmptyView {
    init(_ key: HelpResourceID, refresh: @escaping (HelpEngine, ResourceLoadHandle<T, E>) async -> Void, @ViewBuilder error: @escaping (E) -> ErrorView, @ViewBuilder content: @escaping (T) -> ContentView) {
        self.data = .init(id: key)
        
        self.refresh = refresh
        self.header = { EmptyView() }
        self.error = error
        self.content = content
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
        await HelpEngine.walkDirectory(engine: engine)
    }
    
    
    TopicPresenter(.init(rawValue: "Help/Introduction.md"))
        .environment(\.helpEngine, engine)
        .frame(width: 400, height: 300)
}

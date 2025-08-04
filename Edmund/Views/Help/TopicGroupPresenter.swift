//
//  TopicGroupPresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI

struct HelpGroupPagePresenter : View {
    let over: LoadedHelpGroup;
    @Binding var selectedID: HelpResourceID?;
    
    @ViewBuilder
    private func content(_ name: String) -> some View {
        HStack {
            Image(systemName: "arrow.right")
            Text(name)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(over.name)
                    .font(.title)
                Spacer()
            }
            
            HStack {
                Text("Group")
                    .font(.subheadline)
                    .italic()
                
                Spacer()
            }
            
            List(selection: $selectedID) {
                Section(header: Text("Topics")) {
                    ForEach(over.topicChildren) { topic in
                        content(topic.name)
                    }
                }
                
                Section(header: Text("Groups")) {
                    ForEach(over.groupChildren) { group in
                        content(group.name)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct LoadedHelpGroupPresenter : View {
    init(data: LoadedHelpGroup) {
        self.data = data
        self.navigationTitle = data.name.isEmpty ? "Edmund Help" : data.name
    }
    init(data: LoadedHelpGroup, title: String) {
        self.data = data
        self.navigationTitle = title
    }
    let data: LoadedHelpGroup;
    let navigationTitle: String;
    
    @State private var selectedID: HelpResourceID? = nil;
    @State private var selected: LoadedHelpResource? = nil;
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Text("Help")
                    .font(.title2)
                
                List(data.children, children: \.children, selection: $selectedID) { element in
                    Text(element.name)
                }
            }
        } detail: {
            VStack {
                if let selected = selected {
                    switch selected {
                        case .topic(let topic):
                            TopicPagePresenter(over: topic)
                        case .group(let group):
                            HelpGroupPagePresenter(over: group, selectedID: $selectedID)
                    }
                }
                else if selectedID != nil {
                    Text("Sorry, but it looks like that topic or group could not be loaded.")
                }
            }.padding()
        }.navigationTitle(navigationTitle)
            .onChange(of: selectedID) { _, selectedID in
                withAnimation {
                    self.selected = if let selectedID = selectedID {
                        data.findChild(id: selectedID)
                    }
                    else {
                        nil
                    }
                }
            }
    }
}

struct GroupFetchErrorPresenter : View {
    let e: GroupFetchError;
    
    var body: some View {
        VStack {
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
                    
                case .topicLoad(let t):
                    Text("A sub-topic could not be loaded. Here are the errors:")
                    TopicErrorView(e: t)
            }
        }
    }
}

struct TopicGroupPresenter : View, HelpPresenterView {
    init() {
        self.key = .init()
    }
    init(_ key: HelpResourceID) {
        self.key = key
    }
    
    private let key: HelpResourceID;
    
    private func refresh(_ engine: HelpEngine, _ data: GroupLoadHandle) async {
        await engine.getGroup(deposit: data)
    }
    
    var body: some View {
        HelpResourcePresenter(key, refresh: refresh, error: GroupFetchErrorPresenter.init, content: LoadedHelpGroupPresenter.init)
    }
}



#Preview {
    let engine = HelpEngine()
    
    TopicGroupPresenter(.init(rawValue: "Help"))
        .environment(\.helpEngine, engine)
        .task {
            await engine.walkDirectory()
        }
}

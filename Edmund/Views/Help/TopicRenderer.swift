//
//  TopicRenderer.swift
//  Edmund
//
//  Created by Hollan on 5/2/25.
//

import SwiftUI
import MarkdownUI

struct TopicView : View {
    @Binding var topic: UUID?;
    let map: Dictionary<UUID, HelpTopic>
    @State private var isError: Bool = false;
    @State private var content: String?;
    
    private func loadContent() {
        do {
            if let id = topic, let topic = map[id] {
                content = try String(contentsOf: topic.url)
            }
        }
        catch {
            print("Unable to open file: \(error)")
        }
    }
    
    @ViewBuilder
    private func groupsSection(_ list: [HelpTopic], kind: LocalizedStringKey) -> some View {
        HStack {
            Text(kind)
                .font(.headline)
            Spacer()
        }
        ForEach(list, id: \.id) { child in
            HStack {
                Image(systemName: "arrow.right")
                Text(child.title)
                    .onTapGesture {
                        self.topic = child.id
                    }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func isAGroup(_ topic: HelpTopic) -> some View {
        let (groups, topics) = topic.splitChildren();
        if !topics.isEmpty {
            groupsSection(topics, kind: "Topics:")
            Divider()
        }
        
        if !groups.isEmpty {
            groupsSection(groups, kind: "Groups:")
            Divider()
        }
    }
    
    @ViewBuilder
    private var isATopic: some View {
        if let content = content {
            GeometryReader { geometry in
                Markdown(content)
                    .background(
                        RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                            .fill(.background.secondary)
                    )
            }
        }
        else {
            Text("Loading")
            ProgressView()
                .task {
                    withAnimation {
                        loadContent()
                    }
                }
        }
    }
    
    var body: some View {
        VStack {
            if let id = topic, let topic = map[id] {
                if isError {
                    Text("The page content could not be loaded. Please report this issue.")
                }
                else {
                    HStack {
                        Text(topic.title)
                            .font(.title)
                        Spacer()
                    }
                    HStack {
                        Text(topic.kind.rawValue)
                            .font(.subheadline)
                            .italic()
                        Spacer()
                    }
                    Divider()
                }
                
                if topic.children != nil {
                    isAGroup(topic)
                }
                else {
                    isATopic
                }
                Spacer()
            }
            else {
                Text("Please select a topic to begin")
                    .italic()
            }
        }.navigationTitle("Edmund Help")
            .padding()
            .onChange(of: topic, { _, _ in
                self.content = nil
            })
    }
}

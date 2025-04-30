//
//  Help.swift
//  Edmund
//
//  Created by Hollan on 4/4/25.
//

import SwiftUI
import MarkdownUI

enum TopicKind : LocalizedStringKey, CaseIterable {
    case topic = "Topic",
        topicGroup = "Topic Group"
}

@Observable
class HelpTopic : Identifiable, Equatable {
    init(url: URL, children: [HelpTopic]?) {
        self.id = UUID();
        
        let titleParts = url.lastPathComponent.split(separator: ".");
        if titleParts.count == 1, let first = titleParts.first {
            self.title = String(first)
        }
        else {
            self.title = titleParts.dropLast().joined(separator: ".");
        }
        
        self.url = url;
        self.children = children;
    }
    
    let id: UUID;
    let title: String;
    let url: URL;
    var children: [HelpTopic]?;
    var kind: TopicKind {
        children != nil ? .topicGroup : .topic
    }
    
    /// Splits the children member, if it exists, into two separate groups. The first one is the sub groups, and the second is the actual topics (leaf nodes)
    func splitChildren() -> ([HelpTopic], [HelpTopic]) {
        guard let children = children else { return ([], []) }
        
        var groups: [HelpTopic] = [], topics: [HelpTopic] = [];
        for child in children {
            if child.kind == .topicGroup {
                groups.append(child)
            }
            else {
                topics.append(child)
            }
        }
        
        return (groups, topics)
    }
    
    static func ==(lhs: HelpTopic, rhs: HelpTopic) -> Bool {
        lhs.title == rhs.title && lhs.url == rhs.url && lhs.children == rhs.children
    }
}

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
                    let (groups, topics) = topic.splitChildren();
                    if !topics.isEmpty {
                        groupsSection(topics, kind: "Topics:")
                        Divider()
                    }
                    
                    if !groups.isEmpty {
                        groupsSection(groups, kind: "Groups:")
                        Divider()
                    }
                    
                    Spacer()
                }
                else {
                    if let content = content {
                        Markdown(content)
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

struct HelpView : View {
    @State private var map: Dictionary<UUID, HelpTopic> = .init()
    @State private var root: [HelpTopic]? = nil;
    @State private var isError = false;
    @State private var currentTopic: HelpTopic.ID? = nil;
    
    private func loadFromDirURL(_ url: URL) -> HelpTopic? {
        guard let resource = try? url.resourceValues(forKeys: [.isDirectoryKey]) else {
            print("The resource dictonary could not be found");
            return nil
        }
        
        let fileManager = FileManager.default;
        let result = HelpTopic(
            url: url,
            children: nil
        );
        map[result.id] = result;
        
        // Walk the directory structure to form its children.
        if let isDirectory = resource.isDirectory, isDirectory {
            var children: [HelpTopic] = [];
            
            if let enumerator = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) {
                for case let path in enumerator {
                    let newChild: HelpTopic;
                    
                    if let resource = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                       let isDirectory = resource.isDirectory,
                       isDirectory {
                        guard let element = loadFromDirURL(path) else {
                            return nil;
                        }
                        
                        newChild = element;
                    }
                    else {
                        newChild = .init(
                            url: path,
                            children: nil
                        )
                    }
                    
                    map[newChild.id] = newChild;
                    children.append(newChild)
                }
            }
            
            result.children = children;
        }
        
        return result
    }
    
    private func loadRoots() async {
        if let url = Bundle.main.url(forResource: "Help", withExtension: nil) {
            let helpUrl = url.appendingPathComponent("Help");
            let documentationUrl = url.appendingPathComponent("Documentation");
            let financesUrl = url.appendingPathComponent("Finances");
            
            guard
                let help = loadFromDirURL(helpUrl),
                let documentation = loadFromDirURL(documentationUrl),
                let finances = loadFromDirURL(financesUrl)
            else {
                await MainActor.run {
                    withAnimation {
                        isError = true;
                    }
                }
                return;
            }
            
            await MainActor.run {
                withAnimation {
                    root = [
                        help,
                        finances,
                        documentation
                    ]
                }
            }
        }
        else {
            await MainActor.run {
                isError = true;
            }
            print("Unable to get bundle URL");
        }
    }
    
    var body: some View {
        NavigationSplitView {
            Text("Help")
                .font(.title)
            
            if let root = root {
                List(root, children: \.children, selection: $currentTopic) { child in
                    Text(child.title)
                }
            }
            else if isError {
                Text("Error!")
                Spacer()
            }
            else {
                VStack {
                    Text("Loading")
                        .italic()
                    ProgressView()
                    Spacer()
                }.task {
                    await loadRoots()
                }
            }
        } detail: {
            if isError {
                Text("The help guides could not be loaded. Please report this issue.")
            }
            else if root == nil {
                Text("Loading guides, please wait")
                    .italic()
            }
            else {
                TopicView(topic: $currentTopic, map: map)
            }
        }
    }
}

#Preview {
    HelpView()
}

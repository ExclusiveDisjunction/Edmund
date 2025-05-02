//
//  Help.swift
//  Edmund
//
//  Created by Hollan on 4/4/25.
//

import SwiftUI

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
        #if DEBUG
        print("load roots called")
        #endif
        
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

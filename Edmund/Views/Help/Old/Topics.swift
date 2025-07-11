//
//  Topics.swift
//  Edmund
//
//  Created by Hollan on 5/2/25.
//

import SwiftUI

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

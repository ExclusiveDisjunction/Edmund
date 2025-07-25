//
//  LoadedHelpResource.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/11/25.
//

import Foundation

/// Represents a topic that is guarenteed to have a file content.
public struct LoadedHelpTopic : HelpResourceCore, Sendable {
    public init(id: HelpResourceID, content: String) {
        self.id = id
        self.content = content
    }
    
    public let id: HelpResourceID;
    /// The topic's file content
    public let content: String;
}
/// A request that can be submitted to the help engine to load a topic.
public struct TopicRequest : HelpResourceCore, Sendable {
    public let id: HelpResourceID;
}

/// A complete tree with topic requests for presenting on the user interface.
public struct LoadedHelpGroup : HelpResourceCore, Identifiable, Sendable {
    public init(id: HelpResourceID, children: [LoadedHelpResource]) {
        self.id = id
        self.children = children
    }
    
    public let id: HelpResourceID;
    /// The children groups and topics of the current group.
    public let children: [LoadedHelpResource];
    
    public func findChild(id: HelpResourceID) -> LoadedHelpResource? {
        for child in children {
            if child.id == id {
                return child
            }
            
            if case .group(let g) = child {
                if let result = g.findChild(id: id) {
                    return result
                }
            }
        }
        
        return nil
    }
    
    public var topicChildren: [LoadedHelpTopic] {
        children.compactMap {
            if case .topic(let t) = $0 { return t } else { return nil }
        }
    }
    public var groupChildren: [LoadedHelpGroup] {
        children.compactMap {
            if case .group(let t) = $0 { return t } else { return nil }
        }
    }
}

/// Either a `TopicRequest` or a `LoadedHelpGroup` instance for presenting on the UI.
public enum LoadedHelpResource : Parentable, HelpResourceCore, Sendable, Identifiable {
    case topic(LoadedHelpTopic)
    case group(LoadedHelpGroup)
    
    public var id: HelpResourceID {
        switch self {
            case .topic(let t): t.id
            case .group(let g): g.id
        }
    }
    /// The children groups/topics associated with this current instance.
    public var children: [LoadedHelpResource]? {
        if case .group(let g) = self {
            g.children
        }
        else {
            nil
        }
    }
}

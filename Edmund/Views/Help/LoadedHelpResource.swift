//
//  LoadedHelpResource.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/11/25.
//

import Foundation

public protocol LoadedHelpResourceBase : Identifiable<HelpResourceID>, Sendable { }
public extension LoadedHelpResourceBase {
    /// The current name of the help resource.
    var name: String {
        id.name
    }
}

/// Represents a topic that is guarenteed to have a file content.
public struct LoadedHelpTopic : LoadedHelpResourceBase, Sendable {
    public init(id: HelpResourceID, content: String) {
        self.id = id
        self.content = content
    }
    
    public let id: HelpResourceID;
    /// The topic's file content
    public let content: String;
}
/// A request that can be submitted to the help engine to load a topic.
public struct TopicRequest : LoadedHelpResourceBase, Sendable {
    public let id: HelpResourceID;
}

/// A complete tree with topic requests for presenting on the user interface.
public struct LoadedHelpGroup : LoadedHelpResourceBase, Identifiable, Sendable {
    public init(id: HelpResourceID, children: [LoadedHelpResource]) {
        self.id = id
        self.children = children
    }
    
    public let id: HelpResourceID;
    /// The children groups and topics of the current group.
    public let children: [LoadedHelpResource];
}

/// Either a `TopicRequest` or a `LoadedHelpGroup` instance for presenting on the UI.
public enum LoadedHelpResource : Parentable, LoadedHelpResourceBase, Sendable, Identifiable {
    case topic(TopicRequest)
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

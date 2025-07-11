//
//  HelpResource.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/11/25.
//

import Foundation

/// An ID to use for all help resources, loaded or not.
/// This ID is constructed as a series of parts separated by '/' (from the file system).
/// It can be constructed back into a string by calling `.rawValue`, and can be parsed from any `String` instance.
/// This can be sent between threads, or saved to an encoder.
public struct HelpResourceID : Hashable, Equatable, Sendable, RawRepresentable, Codable {
    public typealias RawValue = String
    
    /// Constructs the ID from a series of pre-separated strings.
    public init(parts: [String]) {
        self.parts = parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    /// Constructs the ID from a string, assumed to be a path.
    public init(rawValue: String) {
        self.parts = rawValue.split(separator: "/", omittingEmptySubsequences: true).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    /// The data associated with this ID.
    public let parts: [String];
    public var rawValue: String {
        return parts.joined(separator: "/")
    }
    /// Obtains the last part of the
    public var name: String {
        parts.last ?? "Error"
    }
    
    public func appending(component: String) -> Self {
        let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return self
        }
        
        return .init(parts: self.parts + [trimmed])
    }
    public func appending(contentsOf: [String]) -> Self {
        let list = self.parts + contentsOf.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter{ !$0.isEmpty }
        
        return .init(parts: list)
    }
}

/// A common protocol for unloaded help resources.
public protocol HelpResourceBase : Identifiable<HelpResourceID>, Sendable {
    /// The physical location on disk for loading
    var url: URL { get }
}
public extension HelpResourceBase {
    /// The name of the current resource
    var name: String {
        id.name
    }
}

/// A reference to a possibly unloaded topic, holding a file path.
public struct HelpTopic : HelpResourceBase, Sendable {
    public init(id: HelpResourceID, url: URL, content: String? = nil) {
        self.id = id
        self.url = url
        self.content = content
    }
    
    public let id: HelpResourceID;
    public let url: URL;
    /// The content of the file, if loaded.
    public var content: String?;
}

/// Represents a directory, or group of other topics or groups.
public struct HelpGroup : HelpResourceBase, Sendable {
    public init(id: HelpResourceID, url: URL, children: [HelpResourceID]) {
        self.id = id
        self.url = url
        self.children = children
    }
    
    public let id: HelpResourceID;
    public let url: URL;
    /// The children identifiers associated with this group.
    public let children: [HelpResourceID]
}

/// A wrapper around help groups and help topics
public enum HelpResource : HelpResourceBase, Sendable {
    case topic(HelpTopic)
    case group(HelpGroup)
    
    public var id: HelpResourceID {
        switch self {
            case .group(let g): g.id
            case .topic(let t): t.id
        }
    }
    public var url: URL {
        switch self {
            case .group(let g): g.url
            case .topic(let t): t.url
        }
    }
    /// The children of the current resource, if they exist.
    public var children: [HelpResourceID]? {
        if case .group(let g) = self {
            g.children
        }
        else {
            nil
        }
    }
}

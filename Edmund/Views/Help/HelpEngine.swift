//
//  HelpEngine.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation

public struct HelpResourceID : Hashable, Equatable, Sendable, RawRepresentable, Codable {
    public typealias RawValue = String
    
    public init(parts: [String]) {
        self.parts = parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    public init(rawValue: String) {
        self.parts = rawValue.split(separator: "/", omittingEmptySubsequences: true).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    public var parts: [String];
    public var rawValue: String {
        return parts.joined(separator: "/")
    }
}

public struct HelpTopic : Identifiable {
    public init(id: HelpResourceID, url: URL, content: String? = nil) {
        self.id = id
        self.url = url
        self.content = content
    }
    
    public let id: HelpResourceID;
    public let url: URL;
    public var content: String?;
}
public struct LoadedHelpTopic : Identifiable, Sendable {
    public init(id: HelpResourceID, content: String) {
        self.id = id
        self.content = content
    }
    
    public let id: HelpResourceID;
    public let content: String;
}
public struct HelpGroup : Identifiable, Sendable {
    public init(id: HelpResourceID, url: URL, children: [HelpResourceID]) {
        self.id = id
        self.url = url
        self.children = children
    }
    
    public let id: HelpResourceID;
    public let url: URL;
    public let children: [HelpResourceID]
}

public enum HelpResource {
    case topic(HelpTopic)
    case group(HelpGroup)
}

public enum TopicFetchError : Error, Sendable {
    case notFound
    case isAGroup
    case fileReadError(String)
    case engineLoading
}

public enum TopicLoadState {
    case loading
    case loaded(LoadedHelpTopic)
    case error(TopicFetchError)
}

@MainActor
@Observable
public class TopicLoadHandle {
    public init(id: HelpResourceID) {
        self.id = id
        self.status = .loading
    }
    
    public var status: TopicLoadState;
    public let id: HelpResourceID;
}

public struct TopicRequest : Identifiable, Sendable {
    public let name: String;
    public let id: HelpResourceID;
}
public struct TopicGroupDetails : Identifiable, Sendable {
    public let name: String;
    public let id: HelpResourceID;
    public let children: [HelpTopicTree];
}

public enum HelpTopicTree : Identifiable, Sendable {
    case topic(TopicRequest)
    case group(TopicGroupDetails)
    
    public var id: HelpResourceID {
        switch self {
            case .topic(let t): t.id
            case .group(let g): g.id
        }
    }
    public var name: String {
        switch self {
            case .topic(let t): t.name
            case .group(let g): g.name
        }
    }
    public var children: [HelpTopicTree]? {
        if case .group(let g) = self {
            return g.children
        }
        else {
            return nil
        }
    }
}

public actor HelpEngine {
    public init() {
        self.data = .init()
        self.cache = .init()
        self.root = .init(id: .init(rawValue: ""), url: .init(filePath: ""), children: [])
    }
    private init(root: HelpGroup, data: [HelpResourceID : HelpResource ]) {
        self.data = data
        self.cache = .init()
        self.root = root
    }
    
    public static func walkDirectory(engine: HelpEngine) async {
        await engine.setIsLoading(true)
        
        await engine.setIsLoading(false)
    }
    
    private var isLoading: Bool = false;
    private var root: HelpGroup;
    private var data: [HelpResourceID : HelpResource]
    private var cache: [HelpResourceID];
    
    private func setIsLoading(_ new: Bool) async {
        isLoading = new
    }
    /// Ensures that the cache is not too full.
    private func registerCache(id: HelpResourceID) {
        guard cache.count > 20 else { return }
        
        //Remove from front, add to the back
        
        // First, unload the current target
        guard let firstId = cache.first, let first = data[firstId], case .topic(var oldTopic) = first else {
            return;
        }
        
        oldTopic.content = nil
        data[firstId] = .topic(oldTopic)
        
        cache.remove(at: 0)
        cache.append(id)
    }
    
    public func getTree() async -> HelpTopicTree? {
        
    }
    
    public func getTopic(id: HelpResourceID) async throws(TopicFetchError) -> LoadedHelpTopic {
        guard !isLoading else {
            throw .engineLoading
        }
        
        guard let resx = data[id] else {
            throw .notFound
        }
        
        guard case .topic(var topic) = resx else {
            throw .isAGroup
        }
        
        if let content = topic.content {
            return .init(id: topic.id, content: content)
        }
        else {
            let content: String;
            let url = topic.url;
            do {
                content = try await Task(priority: .background) {
                    return try String(contentsOf: url)
                }.value
            }
            catch let e {
                throw .fileReadError(e.localizedDescription)
            }
            
            self.registerCache(id: id)
            topic.content = content
            data[id] = .topic(topic) //Update with new content
            
            let loaded = LoadedHelpTopic(id: id, content: content)
            return loaded
        }
    }
    public func getTopic(deposit: TopicLoadHandle) async {
        await MainActor.run {
            deposit.status = .loading
        }
        let id = await MainActor.run {
            deposit.id
        }
        
        let result: LoadedHelpTopic;
        do {
            result = try await self.getTopic(id: id)
        }
        catch {
            await MainActor.run {
                deposit.status = .error(error)
            }
            
            return
        }
        
        await MainActor.run {
            deposit.status = .loaded(result)
        }
    }
}

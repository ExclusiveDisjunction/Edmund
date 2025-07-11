//
//  HelpEngine.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation

public enum TopicFetchError : Error, Sendable {
    case notFound
    case isAGroup
    case fileReadError(String)
    case engineLoading
}
public enum GroupFetchError : Error, Sendable {
    case notFound
    case isATopic
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

public actor HelpEngine {
    public init() {
        self.data = .init()
        self.cache = .init()
    }
    private init(data: [HelpResourceID : HelpResource ]) {
        self.data = data
        self.cache = .init()
    }
    
    /// Walks a directory, inserting all elements it finds into the engine, and returns all direct resource ID's for children notation.
    private static func walkDirectory(engine: HelpEngine, topID: HelpResourceID, url: URL) async -> [HelpResourceID] {
        guard let resource = try? url.resourceValues(forKeys: [.isDirectoryKey]) else {
            return [];
        }
        let fileManager = FileManager.default;
        
        var result: [HelpResourceID] = [];
        
        if let isDirectory = resource.isDirectory, isDirectory {
            if let enumerator = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) {
                for case let path in enumerator {
                    let newId = topID.appending(component: path.lastPathComponent);
                    result.append(newId)
                    
                    if let resource = try? path.resourceValues(forKeys: [.isDirectoryKey]), let isDirectory = resource.isDirectory, isDirectory {
                        let children = await Self.walkDirectory(engine: engine, topID: newId, url: path)
                        
                        await engine.directRegister(
                            id: newId,
                            to: .group(
                                HelpGroup(
                                    id: newId,
                                    url: path,
                                    children: children
                                )
                            )
                        )
                    }
                    else {
                        await engine.directRegister(
                            id: newId,
                            to: .topic(
                                HelpTopic(
                                    id: newId,
                                    url: path
                                )
                            )
                        )
                    }
                }
            }
        }
        
        return result
    }
    public static func walkDirectory(engine: HelpEngine) async {
        await engine.setIsLoading(true)
        
        guard let url = Bundle.main.url(forResource: "Help", withExtension: nil) else {
            print("Unable to find help content base directory.")
            return
        }
        
        let rootId = HelpResourceID(parts: [])
        //The root must be written in the data as a TopicGroup, so the directory must be walked.
        let children = await Self.walkDirectory(engine: engine, topID: rootId, url: url)
        await engine.directRegister(
            id: rootId,
            to: .group(
                HelpGroup(
                    id: rootId,
                    url: url,
                    children: children
                )
            )
        )
        
        await engine.setIsLoading(false)
    }
    
    private var isLoading: Bool = false;
    private var rootId: HelpResourceID = .init(parts: [])
    private var data: [HelpResourceID : HelpResource]
    private var cache: [HelpResourceID];
    
    private func setRootId(_ to: HelpResourceID) {
        self.rootId = to
    }
    private func directRegister(id: HelpResourceID, to: HelpResource) {
        self.data[id] = to
    }
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
    
    public func getTree() async throws(GroupFetchError) -> [LoadedHelpResource] {
        let rootGroup = try await self.getGroup(id: rootId)
        
        return rootGroup.children
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
    public func getTopic(request: TopicRequest) async throws(TopicFetchError) -> LoadedHelpTopic {
        return try await self.getTopic(id: request.id)
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
    
    private func walkGroup(group: HelpGroup) async -> [LoadedHelpResource] {
        var result: [LoadedHelpResource] = [];
        for child in group.children {
            guard let resolved = data[child] else {
                 //Could not resolve the id, so we just move on
                continue;
            }
            
            switch resolved {
                case .group(let g):
                    let children = await self.walkGroup(group: g)
                    result.append(
                        .group(LoadedHelpGroup(id: g.id, children: children))
                    )
                case .topic(let t):
                    result.append(
                        .topic(TopicRequest(id: t.id))
                    )
            }
        }
        
        return result
    }
    public func getGroup(id: HelpResourceID) async throws(GroupFetchError) -> LoadedHelpGroup {
        guard !isLoading else {
            throw .engineLoading
        }
        
        guard let resx = data[id] else {
            throw .notFound
        }
        
        guard case .group(let group) = resx else {
            throw .isATopic
        }
        
        //From this point on, we have the group, we need to resolve all children recursivley.
        let children = await self.walkGroup(group: group);
        let root = LoadedHelpGroup(id: id, children: children);
        
        return root;
    }
}

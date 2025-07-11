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

public enum ResourceLoadState<T, E> where T: LoadedHelpResourceBase, E: Sendable, E: Error {
    case loading
    case loaded(T)
    case error(E)
}
public typealias TopicLoadState = ResourceLoadState<LoadedHelpTopic, TopicFetchError>;
public typealias GroupLoadState = ResourceLoadState<LoadedHelpGroup, GroupFetchError>;

@MainActor
@Observable
public class ResourceLoadHandle<T, E> : Identifiable where T: LoadedHelpResourceBase, E: Sendable, E: Error {
    public init(id: HelpResourceID) {
        self.id = id
        self.status = .loading
    }
    
    public var status: ResourceLoadState<T, E>;
    public let id: HelpResourceID;
}
public typealias TopicLoadHandle = ResourceLoadHandle<LoadedHelpTopic, TopicFetchError>;
public typealias GroupLoadHandle = ResourceLoadHandle<LoadedHelpGroup, GroupFetchError>;

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
    private static func walkDirectory(engine: HelpEngine, topID: HelpResourceID, url: URL, fileManager: FileManager) async -> [HelpResourceID]? {
        guard let resource = try? url.resourceValues(forKeys: [.isDirectoryKey]) else {
            return nil;
        }
        
        var result: [HelpResourceID] = [];
        
        if let isDirectory = resource.isDirectory, isDirectory {
            guard let enumerator = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) else {
                return nil
            }
            
            for case let path in enumerator {
                let newId = topID.appending(component: path.lastPathComponent);
                result.append(newId)
                
                if let resource = try? path.resourceValues(forKeys: [.isDirectoryKey]), let isDirectory = resource.isDirectory, isDirectory {
                    guard let children = await Self.walkDirectory(engine: engine, topID: newId, url: path, fileManager: fileManager) else {
                        continue
                    }
                    
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
        
        return result
    }
    @discardableResult
    public static func walkDirectory(engine: HelpEngine, fileManager: FileManager = .default) async -> Bool {
        guard let url = Bundle.main.url(forResource: "Help", withExtension: nil) else {
            print("Unable to find help content base directory.")
            return false
        }
        
        return await Self.walkDirectory(engine: engine, baseURL: url, fileManager: fileManager)
    }
    @discardableResult
    public static func walkDirectory(engine: HelpEngine, baseURL url: URL, fileManager: FileManager = .default) async -> Bool {
        let rootId = HelpResourceID(parts: [])
        //The root must be written in the data as a TopicGroup, so the directory must be walked.
        guard let children = await Self.walkDirectory(engine: engine, topID: rootId, url: url, fileManager: fileManager) else {
            return false
        }
        
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
        
        await engine.registerWalk()
        return true
    }
    
    private var walked: Bool = false;
    private var rootId: HelpResourceID = .init(parts: [])
    private var data: [HelpResourceID : HelpResource]
    private var cache: [HelpResourceID];
    
    public func getAllData() -> [String] {
        data.map { key, value in
            "\(key) -> \(value.name):\(value.isTopic ? "Topic" : "Group")"
        }
    }
    
    private func setRootId(_ to: HelpResourceID) {
        self.rootId = to
    }
    private func directRegister(id: HelpResourceID, to: HelpResource) {
        self.data[id] = to
    }
    private func registerWalk() {
        self.walked = true
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
        guard walked else {
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
        guard walked else {
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
    public func getGroup(deposit: GroupLoadHandle) async {
        await MainActor.run {
            deposit.status = .loading
        }
        let id = await MainActor.run {
            deposit.id
        }
        
        let result: LoadedHelpGroup;
        do {
            result = try await self.getGroup(id: id)
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

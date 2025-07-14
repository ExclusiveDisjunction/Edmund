//
//  HelpEngine.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation
import SwiftUI

/// A universal system to index, manage, cache, and produce different help topics & groups over some physical directory.
public actor HelpEngine {
    public init() {
        self.data = .init()
    }
    
    /// Walks a directory, inserting all elements it finds into the engine, and returns all direct resource ID's for children notation.
    private func walkDirectory(topID: HelpResourceID, url: URL) async -> [HelpResourceID]? {
        let fileManager = FileManager.default
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
                    guard let children = await self.walkDirectory(topID: newId, url: path) else {
                        continue
                    }
                    
                    self.data[newId] = .group(
                        HelpGroup(
                            id: newId,
                            url: path,
                            children: children
                        )
                    )
                }
                else {
                    self.data[newId] = .topic(
                        HelpTopic(
                            id: newId,
                            url: path
                        )
                    )
                }
            }
        }
        
        return result
    }
    
    /// Walks the default pacakge help directory, recording all groups (folders) and topics (files) it finds.
    @discardableResult
    public func walkDirectory() async -> Bool {
        guard let url = Bundle.main.url(forResource: "Help", withExtension: nil) else {
            print("Unable to find help content base directory.")
            return false
        }
        
        return await self.walkDirectory(baseURL: url)
    }
    
    /// Walks a specific base URL, recording all groups (folders) and topics (files) it finds.
    @discardableResult
    public func walkDirectory(baseURL url: URL) async -> Bool {
        let rootId = HelpResourceID(parts: [])
        //The root must be written in the data as a TopicGroup, so the directory must be walked.
        guard let children = await self.walkDirectory(topID: rootId, url: url) else {
            return false
        }
        
        self.data[rootId] = .group(
            HelpGroup(
                id: rootId,
                url: url,
                children: children
            )
        )
        
        self.walked = true
        return true
    }
    
    /// Represents the engine being unloaded. When false, retreiving data returns .notLoaded.
    private var walked: Bool = false;
    /// The root ID from the top of the directory.
    private var rootId: HelpResourceID = .init(parts: [])
    /// All topics and groups recognized by the engine.
    private var data: [HelpResourceID : HelpResource]
    /// The ID of values that have been cached.
    private var cache: LimitedQueue<HelpResourceID> = .init(capacity: 20, with: .init(parts: []));
    
    /// Instructs the engine to wipe all data.
    public func reset() async {
        if !walked { return }
        
        self.walked = false
        self.data = [:]
        self.cache.clear()
    }
    
    /// Ensures that the cache is not too full.
    private func registerCache(id: HelpResourceID) {
        if let oldId = cache.append(id) {
            //Get the old element
            
            guard let first = data[oldId], case .topic(var oldTopic) = first else {
                // Didnt resolve correctly, but that is ok
                return;
            }
            
            // Unload the data and update the internal data
            oldTopic.content = nil;
            self.data[oldId] = .topic(oldTopic)
        }
    }
    
    /// Loads a topic from the engine from a specified `HelpResourceID`.
    /// If the topic could not be found/resolved correctly, or the engine is loading, this will throw an error.
    /// - Parameters:
    ///     - id: The specified ID of the topic to load.
    /// - Returns:
    ///     - A `LoadedHelpTopic`, containing all topic information.
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
    /// Loads a topic from the engine from a specified `TopicRequest`.
    /// If the topic could not be found/resolved correctly, or the engine is loading, this will throw an error.
    /// - Parameters:
    ///     - request: The request to load a specified topic.
    /// - Returns:
    ///     - A `LoadedHelpTopic`, containing all topic information.
    public func getTopic(request: TopicRequest) async throws(TopicFetchError) -> LoadedHelpTopic {
        return try await self.getTopic(id: request.id)
    }
    /// Loads a topic from the engine and deposits the information into a `TopicLoadHandle`.
    /// Any errors occuring from the engine will be placed as `.error()` in the `deposit` handle.
    /// - Parameters:
    ///     - deposit: The specified handle (id and status updater) to load the resources from the engine.
    public func getTopic(deposit: TopicLoadHandle) async {
        await MainActor.run {
            withAnimation {
                deposit.status = .loading
            }
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
                withAnimation {
                    deposit.status = .error(error)
                }
            }
            
            return
        }
        
        await MainActor.run {
            withAnimation {
                deposit.status = .loaded(result)
            }
        }
    }
    
    /// Using `data` and some `HelpGroup`, this will walk the tree and resolve all children into a `[LoadedHelpResource]` package.
    /// This function is self-recursive, as it walks the entire tree structure starting at `group`.
    /// - Parameters:
    ///     - group: The root node to start walking from
    /// - Returns:
    ///     - All children under `group`, as loaded resources.
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
    /// Loads a group from the engine from a specified `HelpResourceID`.
    /// If the group could not be found/resolved correctly, or the engine is loading, this will throw an error.
    /// - Parameters:
    ///     - id: The specified ID of the group to load.
    /// - Returns:
    ///     - A `LoadedHelpGroup` instance with information to load all children resources.
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
    /// Loads a group from the engine and deposits the information into a `GroupLoadHandle`.
    /// Any errors occuring from the engine will be placed as `.error()` in the `deposit` handle.
    /// - Parameters:
    ///     - deposit: The specified handle (id and status updater) to load the resources from the engine.
    public func getGroup(deposit: GroupLoadHandle) async {
        await MainActor.run {
            withAnimation {
                deposit.status = .loading
            }
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
                withAnimation {
                    deposit.status = .error(error)
                }
            }
            
            return
        }
        
        await MainActor.run {
            withAnimation {
                deposit.status = .loaded(result)
            }
        }
    }
    
    /// Loads the entire engine's tree, and returns the top level resources.
    /// See the documentation for `.getGroup(id:)` for information about errors.
    public func getTree() async throws(GroupFetchError) -> LoadedHelpGroup {
        try await self.getGroup(id: rootId)
    }
    /// Loads the engire engine's tree and places the result into a `WholeTreeLoadHandle`, as updates occur.
    /// - Parameters:
    ///     - deposit: The location to send updates about the fetch to.
    public func getTree(deposit: GroupLoadHandle) async {
        await MainActor.run {
            deposit.status = .loading
        }
        
        let result: LoadedHelpGroup;
        do {
            result = try await self.getTree()
        }
        catch let e {
            await MainActor.run {
                deposit.status = .error(e)
            }
            
            return
        }
        
        await MainActor.run {
            deposit.status = .loaded(result)
        }
    }
}

public struct HelpEngineKey : EnvironmentKey {
    public typealias Value = HelpEngine;
    
    public static var defaultValue: HelpEngine {
        .init()
    }
}
public extension EnvironmentValues {
    var helpEngine: HelpEngine {
        get { self[HelpEngineKey.self] }
        set { self[HelpEngineKey.self] = newValue }
    }
}

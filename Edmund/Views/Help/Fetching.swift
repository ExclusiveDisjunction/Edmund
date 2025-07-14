//
//  Fetching.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import Observation

/// An error representing what can go wrong when fetching a `HelpTopic` instance into a `LoadedHelpTopic` instance.
public enum TopicFetchError : Error, Sendable {
    case notFound
    case isAGroup
    case fileReadError(String)
    case engineLoading
}
/// An error representing what can go wrong when fetching a `HelpGroup` instance into a `LoadedHelpGroup` instance.
public enum GroupFetchError : Error, Sendable {
    case notFound
    case isATopic
    case engineLoading
}

/// A status system used to indicate the stage in which a resource (`T`) gets fetched.
/// Includes information about any errors, stored as `E`.
public enum ResourceLoadState<T, E> where E: Sendable, E: Error {
    case loading
    case loaded(T)
    case error(E)
}
extension ResourceLoadState : Sendable where T: Sendable { }

/// The load state for help topics.
public typealias TopicLoadState = ResourceLoadState<LoadedHelpTopic, TopicFetchError>;
/// The load state for help groups.
public typealias GroupLoadState = ResourceLoadState<LoadedHelpGroup, GroupFetchError>;

public protocol ResourceLoadHandleBase : AnyObject, Observable {
    associatedtype T
    associatedtype E: Sendable, Error
    
    @MainActor
    var status: ResourceLoadState<T, E> { get set }
}

/// An Observable class that can be used to record the process of loading some `id`, using `ResourceLoadState` to record progress.
@MainActor
@Observable
public class ResourceLoadHandle<T, E> : ResourceLoadHandleBase, Identifiable where T: Identifiable, T.ID: Sendable, E: Sendable, E: Error {
    @MainActor
    public init(id: T.ID) {
        self.id = id
        self.status = .loading
    }
    
    /// The current status of the fetching process.
    /// This is `MainActor` isolated.
    public var status: ResourceLoadState<T, E>;
    /// The ID of the data to be fetched.
    public let id: T.ID;
}
/// The loading handle for help topics.
public typealias TopicLoadHandle = ResourceLoadHandle<LoadedHelpTopic, TopicFetchError>;
/// The loading handle for help groups.
public typealias GroupLoadHandle = ResourceLoadHandle<LoadedHelpGroup, GroupFetchError>;

/// An Observable class that can be used to record the process of loading the entire topic tree from the `HelpEngine`.
@MainActor
@Observable
public class WholeTreeLoadHandle : ResourceLoadHandleBase {
    public init() {
        self.status = .loading
    }
    
    /// The current status of the fetching process.
    public var status: ResourceLoadState<[LoadedHelpResource], GroupFetchError>;
}

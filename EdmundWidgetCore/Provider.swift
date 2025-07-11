//
//  Untitled.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/5/25.
//

import Foundation
import WidgetKit

/// Represents information that has been processed (encoded) from a `WidgetDataManager`.
public struct ProcessedData : Sendable {
    /// The output URL name to store the data into.
    let name: String
    /// The data to write
    let data: Data;
}

/// An actor that syncs access to written data for a `WidgetDataProvider`.
public actor WidgetDataEngine {
    /// Creates the engine with empty values
    public init() {
        self.finalized = .init()
    }
    
    /// The completed data instances.
    public fileprivate(set) var finalized: [ProcessedData];
    
    /// Writes a specific `WidgetDataManager`'s content into the engine.
    public func include<T>(from: T) async throws where T: WidgetDataManager {
        let name = T.outputName;
        let result = await from.process()
        let data = try JSONEncoder().encode(result)
        
        self.finalized.append(.init(name: name, data: data))
    }
    public func submit(name: String, data: Data) async {
        self.finalized.append(.init(name: name, data: data))
    }
}

/// A centralized system that allows for reading and writing of widget data out of a centralized storage location.
public struct WidgetDataProvider : Sendable, Copyable {
    /// Attempts to open the provider over the default store location.
    public init?() {
        self.engine = .init()
        guard let url = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.defaultStore) else {
            return nil
        }
        
        self.baseUrl = url
    }
    public init(url: URL) {
        self.engine = .init()
        self.baseUrl = url
    }
    
    private let baseUrl: URL;
    public let engine: WidgetDataEngine
    
    public static let defaultStore: String = "group.com.exdisj.Edmund.WidgetData";
    
    public func append<T>(data: T) async throws where T: WidgetDataManager {
        try await self.engine.include(from: data)
    }
    
    public func write() async throws {
        for item in await engine.finalized {
            let currentUrl = baseUrl.appendingPathComponent(item.name)
            
            try await Task.detached(priority: .background) {
                try item.data.write(to: currentUrl, options: .atomic)
            }.value
        }
    }
    public func read<T>(name: String) async throws -> T where T: Decodable {
        let data = try await Task.detached(priority: .background) {
            try Data(contentsOf: baseUrl.appendingPathComponent(name))
        }.value
        
        await self.engine.submit(name: name, data: data)
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public consuming func prepareWidget() async throws {
        try await self.write()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /* I dont even know if this is needed...
     #if os(iOS)
     public static let backgroundTaskID: String = "com.exdisj.edmund.widgetRefresh"
     
     private consuming func handleAppRefresh(task: BGTask) {
     scheduleWidgetRefresh()
     
     task.expirationHandler = {
     print("The widget refresh background task has been canceled")
     }
     
     Task {
     do {
     try await self.prepareWidget()
     }
     catch let e {
     print("Unable to save background task work \(e)")
     task.setTaskCompleted(success: false)
     }
     task.setTaskCompleted(success: true)
     }
     
     }
     
     private func scheduleWidgetRefresh() {
     let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskID)
     request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 24 * 60) //10 days
     
     do {
     try BGTaskScheduler.shared.submit(request)
     print("Background task scheduled")
     }
     catch {
     print("The background task could not be scheduled, error: \(error)")
     }
     }
     public func registerWidgetRefresh() {
     BGTaskScheduler.shared.register(
     forTaskWithIdentifier: Self.backgroundTaskID,
     using: nil,
     launchHandler: handleAppRefresh
     )
     }
     #endif
     */
}

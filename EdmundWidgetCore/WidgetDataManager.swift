//
//  WidgetDataManager.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/2/25.
//

import Foundation
import SwiftData
import WidgetKit

#if os(iOS)
import BackgroundTasks
#endif

public let dataStoreIdentifier: String = "group.com.exdisj.Edmund.WidgetData";

public protocol WidgetDataManager : Sendable {
    associatedtype Output: Codable, Sendable
    static var outputName: String { get }
    
    func process() async -> Output;
}

struct ProcessedData : Sendable {
    let name: String
    let data: Data;
}

public actor WidgetDataEngine {
    public init() {
        self.finalized = .init()
    }
    
    fileprivate var finalized: [ProcessedData];
    
    public func include<T>(from: T) async throws where T: WidgetDataManager {
        let name = T.outputName;
        let result = await from.process()
        let data = try JSONEncoder().encode(result)
        
        self.finalized.append(.init(name: name, data: data))
    }
}

public struct WidgetDataProvider : Sendable, Copyable {
    public init() {
        self.engine = .init()
    }
    
    public let engine: WidgetDataEngine
    
    public func append<T>(data: T) async throws where T: WidgetDataManager {
        try await self.engine.include(from: data)
    }
    
    public func write() async throws -> Bool {
        guard let fileUrl = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: dataStoreIdentifier) else {
            print("unable to resolve the bundle URL")
            return false
        }
        
        for item in await engine.finalized {
            let currentUrl = fileUrl.appendingPathComponent(item.name)
            
            try await Task.detached(priority: .background) {
                try item.data.write(to: currentUrl, options: .atomic)
            }.value
        }
        
        return true
    }
    
    public consuming func prepareWidget() {
        Task {
            let result: Bool;
            do {
                result = try await self.write()
            }
            catch let e {
                print("write failure: \(e.localizedDescription)")
                result = false;
            }
            
            if !result {
                return
            }
            
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    #if os(iOS)
    public static let backgroundTaskID: String = "com.exdisj.edmund.widgetRefresh"
    
    private consuming func handleAppRefresh(task: BGTask) {
        scheduleWidgetRefresh()
        
        task.expirationHandler = {
            print("The widget refresh background task has been canceled")
        }
        
        self.prepareWidget()
        task.setTaskCompleted(success: true)
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
}

//
//  WidgetDataManager.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/2/25.
//

import Foundation
import SwiftData



public protocol WidgetDataManager : Sendable {
    associatedtype Output: Codable, Sendable
    static var outputName: String { get }
    
    func process() async -> Output;
}
public extension WidgetDataManager {
    static func extractFromProvider(provider: WidgetDataProvider) async throws -> Self.Output {
        return try await provider.read(name: Self.outputName)
    }
}

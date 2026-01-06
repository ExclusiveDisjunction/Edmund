//
//  WidgetDataManager.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/2/25.
//

import Foundation
import SwiftData

public protocol WidgetDataBundle : Sendable {
    associatedtype Output: Codable, Sendable
    static var outputName: String { get }
    
    func process() async -> Output;
}

//
//  LoggerSystem.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/14/25.
//

import os
import SwiftUI

public struct LoggerSystem : Sendable {
    public init() {
        self.app    = Logger(subsystem: Self.bundleID, category: "App Messages")
        self.help   = Logger(subsystem: Self.bundleID, category: "Help Engine")
        self.unique = Logger(subsystem: Self.bundleID, category: "Unique Engine")
        self.data   = Logger(subsystem: Self.bundleID, category: "Data Messages")
    }
    
    public static let bundleID: String = "com.exdisj.Edmund";
    
    public let app: Logger;
    public let help: Logger;
    public let unique: Logger;
    public let data: Logger;
}

fileprivate struct LoggerSystemKey: EnvironmentKey {
    typealias Value = LoggerSystem?;
    
    static var defaultValue: LoggerSystem? {
        nil
    }
}

public extension EnvironmentValues {
    var loggerSystem: LoggerSystem? {
        get { self[LoggerSystemKey.self] }
        set { self[LoggerSystemKey.self] = newValue }
    }
}

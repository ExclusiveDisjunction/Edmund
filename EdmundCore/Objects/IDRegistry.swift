//
//  IDRegistry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import Foundation
import SwiftData

@Observable
public class IDRegistry {
    public init() {
        data = .init()
        invalid = .init()
    }
    
    @MainActor
    public func register<T>(type: T.Type = T.self, context: ModelContext) async -> Bool where T: PersistentModel, T: Identifiable<String> {
        guard let data = try? context.fetch(FetchDescriptor<T>()) else {
            return false;
        }
        
        register(data: data);
        return true;
    }
    public func register<T>(data: [T]) where T: Identifiable<String> {
        for item in data {
            
        }
    }
    
    public var data: Dictionary<ObjectIdentifier, String>
    private var invalid: Dictionary<ObjectIdentifier, [String]>;
}

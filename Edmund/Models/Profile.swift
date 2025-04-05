//
//  Profile.swift
//  Edmund
//
//  Created by Hollan on 4/3/25.
//

import Foundation
import SwiftData

@Model
public class Profile: Identifiable, Hashable, Equatable {
    public init(_ name: String) {
        self.name = name
    }
    
    public var id: String { name }
    @Attribute(.unique) public var name: String;
    
    #if DEBUG
    static let debugProfiles: [Profile] = {
       [
        .init("Debug"),
        .init("Personal")
       ]
    }()
    #endif
}

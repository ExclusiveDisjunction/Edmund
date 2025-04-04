//
//  Profile.swift
//  Edmund
//
//  Created by Hollan on 4/3/25.
//

import Foundation
import SwiftData

@Model
class Profile: Identifiable, Hashable, Equatable {
    init(_ name: String) {
        self.name = name
    }
    
    var id: String { name }
    @Attribute(.unique) var name: String;
    
    static let debugProfiles: [Profile] = {
       [
        .init("Debug"),
        .init("Personal")
       ]
    }()
}

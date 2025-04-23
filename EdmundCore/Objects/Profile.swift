//
//  Profile.swift
//  Edmund
//
//  Created by Hollan on 4/3/25.
//

import Foundation
import SwiftData

@Model
public final class Profile: Identifiable, Hashable, Equatable, InspectableElement, EditableElement {
    public typealias InspectorView = SimpleElementInspect<Profile>
    public typealias EditView = SimpleElementEdit<Profile>
    public typealias Snapshot = SimpleElementSnapshot<Profile>
    
    public init(_ name: String) {
        self.name = name
    }
    
    public var id: String { name }
    @Attribute(.unique) public var name: String;
    
    #if DEBUG
    public static let debugProfiles: [Profile] = {
       [
        .init("Debug"),
        .init("Personal")
       ]
    }()
    #endif
}

//
//  Inspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/2/25.
//

import SwiftUI
import Foundation

enum InspectionMode {
    case edit, view
}

@Observable
class InspectionManifest<T> where T: Identifiable {
    var mode: InspectionMode = .view
    var value: T?
    
    func open(_ value: T, mode: InspectionMode) {
        self.value = value
        self.mode = mode
    }
}

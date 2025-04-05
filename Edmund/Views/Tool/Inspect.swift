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

struct InspectionManifest<T> : Identifiable where T: Identifiable {
    let mode: InspectionMode
    let value: T
    var id: T.ID { value.id }
}

extension FocusedValues {

}

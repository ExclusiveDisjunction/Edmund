//
//  InspectEditTitle.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftUI

/// A simplification of the title used for the various Inspector and Editor views.
public struct InspectEditTitle<T> : View where T: TypeTitled {
    public init(mode: InspectionMode = .inspect) {
        self.mode = mode
    }
    
    @State private var mode: InspectionMode;
    
    public var body: some View {
        Text(mode == .edit ? T.typeDisplay.edit : mode == .add ? T.typeDisplay.add : T.typeDisplay.inspect)
            .font(.title2)
    }
}

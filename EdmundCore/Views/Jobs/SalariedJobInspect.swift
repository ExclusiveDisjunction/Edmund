//
//  SalariedJobinspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

public struct SalariedJobInspector : ElementInspectorView {
    public typealias For = SalariedJob
    
    public init(_ data: Self.For) {
        self.data = data
    }
    
    private var data: SalariedJob;
    
    public var body: some View {
        Grid {
            GridRow {
                
            }
        }
    }
}

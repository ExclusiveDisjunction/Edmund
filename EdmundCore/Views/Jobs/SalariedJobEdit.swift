//
//  SalariedJobEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

public struct SalariedJobEdit : ElementEditorView {
    public typealias For = SalariedJob;
    
    public init(_ snapshot: SalariedJobSnapshot) {
        self.snapshot = snapshot;
    }
    
    @Bindable private var snapshot: SalariedJobSnapshot;
    
    public var body: some View {
        Grid {
            GridRow {
                
            }
        }
    }
}

#Preview {
    ElementEditor(SalariedJob(), adding: true)
        .modelContainer(Containers.debugContainer)
}

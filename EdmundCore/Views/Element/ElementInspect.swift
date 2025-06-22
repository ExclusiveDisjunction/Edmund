//
//  ElementInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftUI
import SwiftData

/// A high level abstraction over element inspection. If `T` is an `InspectableElement`, then it will load the inspector view, and handle the layout/closing actions for the process.
public struct ElementInspector<T> : View where T: InspectableElement {
    public init(data: T) {
        self.data = data
    }
    private let data: T;
    
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            InspectEditTitle<T>()
            
            Divider()
            
            T.InspectorView(data)
            
            HStack{
                Spacer()
                
                Button("Ok", action: { dismiss() })
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

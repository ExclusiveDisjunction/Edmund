//
//  SimpleElementEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData;
import SwiftUI;

/// A simple `ElementSnapshot` class for any  `NamedEditableElement`.
@Observable
public final class SimpleElementSnapshot<T> : ElementSnapshot where T: NamedEditableElement {
    public typealias Host = T;
    
    public init(_ from: T) {
        self.name = from.name;
    }
    
    /// The name of the element to edit.
    public var name: String;
    
    public func validate() -> Bool {
        !name.isEmpty;
    }
    public func apply(_ to: T, context: ModelContext) {
        to.name = name;
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name);
    }
    public static func == (lhs: SimpleElementSnapshot<T>, rhs: SimpleElementSnapshot<T>) -> Bool {
        lhs.name == rhs.name
    }
}

/// A simple element editor for any type that uses `ElementSnapshot` as its snapshot type.
public struct SimpleElementEdit<T> : ElementEditorView where T: NamedEditableElement, T.Snapshot == SimpleElementSnapshot<T> {
    public typealias For = T;
    
    @Bindable private var snapshot: T.Snapshot;
    public init(_ snapshot: T.Snapshot){
        self.snapshot = snapshot;
    }
     
#if os(macOS)
    private let minWidth: CGFloat = 60;
    private let maxWidth: CGFloat = 70;
#else
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#endif
    
    public var body: some View {
        HStack {
            Text("Name:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            TextField("", text: $snapshot.name)
                .textFieldStyle(.roundedBorder)
        }
    }
}

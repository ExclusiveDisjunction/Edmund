//
//  SimpleElementEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData;
import SwiftUI;

public final class SimpleElementSnapshot<T> : ElementSnapshot where T: EditableElement {
    public typealias Host = T;
    
    public init(_ from: T) {
        self.name = from.name;
    }
    
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
public struct SimpleElementEdit<T> : ElementEditorView where T: EditableElement, T.Snapshot == SimpleElementSnapshot<T> {
    public typealias For = T;
    
    @StateObject private var snapshot: T.Snapshot;
    public init(_ snapshot: T.Snapshot){
        self._snapshot = .init(wrappedValue: snapshot);
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
            Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            TextField("Name", text: $snapshot.name).labelsHidden().textFieldStyle(.roundedBorder)
            
            Spacer()
        }
    }
}

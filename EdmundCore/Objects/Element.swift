//
//  Found.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import Foundation;
import Combine;
import SwiftUI;
import SwiftData;

public protocol InspectableElement : AnyObject, Identifiable {
    associatedtype InspectorView: ElementInspectorView where InspectorView.For == Self;
    
    var name: String { get }
}
public protocol EditableElement : AnyObject, Identifiable {
    associatedtype EditView: ElementEditorView where EditView.For == Self;
    associatedtype Snapshot: ElementSnapshot where Snapshot.Host == Self;
    
    var name: String { get set }
}

public protocol ElementSnapshot: AnyObject, ObservableObject, Hashable, Equatable, Identifiable {
    associatedtype Host: EditableElement;
    
    init(_ from: Host);
    
    func apply(_ to: Host, context: ModelContext);
    func validate() -> Bool;
}

public protocol ElementInspectorView : View {
    associatedtype For: InspectableElement;
    
    init(_ data: For);
}
public protocol ElementEditorView : View {
    associatedtype For: EditableElement;
    
    init(_ data: For.Snapshot);
}

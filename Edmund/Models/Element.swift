//
//  Found.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import Foundation;
import SwiftUI;
import SwiftData;

protocol InspectableElement : AnyObject, Identifiable {
    associatedtype InspectorView: ElementInspectorView where InspectorView.For == Self;
    
    var name: String { get }
}
protocol EditableElement : AnyObject, Identifiable {
    associatedtype EditView: ElementEditorView where EditView.For == Self;
    associatedtype Snapshot: ElementSnapshot where Snapshot.Host == Self;
    
    var name: String { get set }
}

protocol ElementSnapshot: AnyObject, Observable, Hashable, Equatable, Identifiable {
    associatedtype Host: EditableElement;
    
    init(_ from: Host);
    
    func apply(_ to: Host, context: ModelContext);
    func validate() -> Bool;
}

protocol ElementInspectorView : View {
    associatedtype For: InspectableElement;
    
    init(_ data: For);
}
protocol ElementEditorView : View {
    associatedtype For: EditableElement;
    
    init(_ data: For.Snapshot);
}

//
//  Found.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import Foundation;
import SwiftUI;
import SwiftData;

protocol InspectableElement : AnyObject, Observable, Identifiable {
    associatedtype InspectorView: ElementInspectorView where InspectorView.For == Self;
    
    var name: String { get }
}
protocol EditableElement : AnyObject, Observable, Identifiable {
    associatedtype EditView: ElementEditView where EditView.For == Self;
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
protocol ElementEditView : View {
    associatedtype For: EditableElement;
    
    init(_ data: For.Snapshot);
}

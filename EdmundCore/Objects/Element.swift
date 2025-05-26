//
//  Found.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import Foundation;
import SwiftUI;
import SwiftData;

/// A type wrapping the display information for a specific data type.
public struct TypeTitleStrings {
    /// A singluar value (Ex. Book)
    public let singular : LocalizedStringKey;
    /// A plural value (Ex. Books)
    public let plural   : LocalizedStringKey;
    /// The title used for inspecting (Ex. Inspect Book)
    public let inspect  : LocalizedStringKey;
    /// The title used for editing (Ex. Edit Book)
    public let edit     : LocalizedStringKey;
    /// The title used for adding (Ex. Add Book)
    public let add      : LocalizedStringKey;
}
/// Represents a type that can have itself be displayed as a title.
public protocol TypeTitled {
    /// The display values that can be used to render the type.
    static var typeDisplay : TypeTitleStrings { get }
}

/// Represents a data type that can be inspected with a dedicated view.
public protocol InspectableElement : AnyObject, Identifiable, TypeTitled {
    /// The associated view that can be used to inspect the properties of the object.
    associatedtype InspectorView: ElementInspectorView where InspectorView.For == Self;
}
/// Represents an inspectable element that also has a name.
public protocol NamedInspectableElement : InspectableElement {
    /// The name of the element
    var name: String { get }
}
/// Represents a data type that can be editied with a dedicated view.
public protocol EditableElement : AnyObject, Identifiable, TypeTitled {
    /// The associated view that can be used to edit the properties of the object.
    associatedtype EditView: ElementEditorView where EditView.For == Self;
    /// An observable class that is used to hold editable values of the object.
    associatedtype Snapshot: ElementSnapshot where Snapshot.Host == Self;
}
/// Represents an editable element that has a writable name.
public protocol NamedEditableElement : EditableElement {
    /// The name of the element
    var name: String { get set }
}

/// Represents a class that can be used to hold the values of an element for editing.
public protocol ElementSnapshot: AnyObject, Observable, Hashable, Equatable, Identifiable {
    /// The data type this holds data for.
    associatedtype Host: EditableElement;
    
    /// Creates an instance using the data from the Host element.
    init(_ from: Host);
    
    /// Sets the host's values to the current values.
    func apply(_ to: Host, context: ModelContext);
    /// Determines if the current values are acceptable to display to the user.
    func validate() -> Bool;
}

/// Represents a view that can be used to inspect a specific element.
public protocol ElementInspectorView : View {
    /// The associated element type.
    associatedtype For: InspectableElement;
    
    /// Constructs the view around this data, so that it can be displayed.
    init(_ data: For);
}
/// Represents a view that can be used to edit a specific element.
public protocol ElementEditorView : View {
    /// The associated element type.
    associatedtype For: EditableElement;
    
    /// Constructs the view around this snapshot, so that it can be editied.
    init(_ data: For.Snapshot);
}

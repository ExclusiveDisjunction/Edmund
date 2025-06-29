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

/// Represents a common functionality between elements.
public protocol ElementBase : AnyObject, Identifiable, TypeTitled { }

public protocol DefaultableElement {
    init()
}

/// Represents a data type that can be inspected with a dedicated view.
public protocol InspectableElement : ElementBase {
    /// The associated view that can be used to inspect the properties of the object.
    associatedtype InspectorView: View;
    
    /// Creates a view that shows all properties of the current element.
    @ViewBuilder
    func makeInspectView() -> InspectorView;
}
/// Represents an inspectable element that also has a name.
public protocol NamedInspectableElement : InspectableElement {
    /// The name of the element
    var name: String { get }
}

/// Represents a data type that can be "snapshoted" and updated from that snapshot at a later time.
public protocol SnapshotableElement : ElementBase, PersistentModel {
    associatedtype Snapshot : ElementSnapshot;
    
    /// Creates a snapshot of the current element
    func makeSnapshot() -> Snapshot;
    /// Creates a snapshot that can be used for adding a blank element.
    static func makeBlankSnapshot() -> Snapshot;
    /// Sets the element's properties to the values in the snapshot.
    /// This is allowed to throw `UniqueFailureError<Host.ID>` if registering in the unique engine fails.
    /// This should not happen in good practice, but must be explored just in case.
    func update(_ from: Snapshot, unique: UniqueEngine) throws(UniqueFailueError<Self.ID>);
}
/// Represents a class that can be used to hold the values of an element for editing.
public protocol ElementSnapshot: AnyObject, Observable, Hashable, Equatable, Identifiable {
    /// Determines if the current values are acceptable to display to the user.
    func validate(unique: UniqueEngine) -> [ValidationFailure];
}

/// Represents a data type that can be editied with a dedicated view.
public protocol EditableElement : ElementBase, SnapshotableElement {
    /// The associated view that can be used to edit the properties of the object.
    associatedtype EditView: View;
    
    /// Creates a view that shows all properties of the element, allowing for editing.
    /// This works off of the snapshot of the element, not the element itself.
    @ViewBuilder
    static func makeEditView(_ snap: Self.Snapshot) -> EditView;
}
/// Represents an editable element that has a writable name.
public protocol NamedEditableElement : EditableElement {
    /// The name of the element
    var name: String { get set }
}

//
//  Elements.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI
import EdmundCore

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
public protocol InspectableElement : ElementBase {
    /// The associated view that can be used to inspect the properties of the object.
    associatedtype InspectorView: View;
    
    /// Creates a view that shows all properties of the current element.
    @MainActor
    @ViewBuilder
    func makeInspectView() -> InspectorView;
}

/// Represents a data type that can be editied with a dedicated view.
public protocol EditableElement : ElementBase, SnapshotableElement {
    /// The associated view that can be used to edit the properties of the object.
    associatedtype EditView: View;
    
    /// Creates a view that shows all properties of the element, allowing for editing.
    /// This works off of the snapshot of the element, not the element itself.
    @MainActor
    @ViewBuilder
    static func makeEditView(_ snap: Self.Snapshot) -> EditView;
}

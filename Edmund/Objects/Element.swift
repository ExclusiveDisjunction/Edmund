//
//  Found.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import Foundation;
import SwiftUI;
import SwiftData;

/// Represents a common functionality between elements.
public protocol ElementBase : AnyObject, Identifiable { }

/// Represents an element that can be constructed with no arguments.
public protocol DefaultableElement {
    init()
}
/// Represents an element that can be constructed with no arguments, but only on the main actor.
public protocol IsolatedDefaultableElement {
    @MainActor
    init()
}

public protocol NamedElement {
    var name: String { get set }
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
    @MainActor
    func update(_ from: Snapshot, unique: UniqueEngine) async throws(UniqueFailureError);
}
public protocol SnapshotConstructableElement : SnapshotableElement {
    @MainActor
    init(snapshot: Self.Snapshot, unique: UniqueEngine) async throws(UniqueFailureError);
}

/// Represents a class that can be used to hold the values of an element for editing.
public protocol ElementSnapshot: AnyObject, Observable, Hashable, Equatable, Identifiable {
    /// Determines if the current values are acceptable to display to the user.
    @MainActor
    func validate(unique: UniqueEngine) async -> ValidationFailure?
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


/// Represents a type that holds `LedgerEntry` values.
public protocol TransactionHolder {
    /// The transactions associated with this type.
    var transactions: [LedgerEntry] { get set }
}
public protocol VoidableElement {
    var isVoided: Bool { get }
    
    /// Sets the void status for the current element, and possibly all elements beneath it to `new`.
    /// If `new` is false, this element and all children beneath will it be `false` as well.
    /// If `new` is true, this element ONLY will be un-voided.
    /// If the new status is different from current status, nothing will happen.
    func setVoidStatus(_ new: Bool);
}
public extension VoidableElement {
    static var voidedFilteredPredicate : Predicate<Self> {
        #Predicate<Self> {
            !$0.isVoided
        }
    }
}


public protocol Displayable {
    var display: LocalizedStringKey { get }
}

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

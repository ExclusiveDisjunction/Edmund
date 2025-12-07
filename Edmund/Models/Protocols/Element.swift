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

public protocol NamedElement : AnyObject {
    var name: String { get set }
}

public protocol VoidableElement {
    var isVoided: Bool { get }
    
    /// Sets the void status for the current element, and possibly all elements beneath it to `new`.
    /// If `new` is false, this element and all children beneath will it be `false` as well.
    /// If `new` is true, this element ONLY will be un-voided.
    /// If the new status is different from current status, nothing will happen.
    func setVoidStatus(_ new: Bool);
}

/// Represents a type that holds `LedgerEntry` values.
public protocol TransactionHolder {
    /// The transactions associated with this type.
    var transactions: [LedgerEntry] { get set }
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
public protocol EditableElement : ElementBase {
    /// The associated view that can be used to edit the properties of the object.
    associatedtype EditView: View;
    
    /// Creates a view that shows all properties of the element, allowing for editing.
    /// This works off of the snapshot of the element, not the element itself.
    @MainActor
    @ViewBuilder
    func makeEditView() -> EditView;
}

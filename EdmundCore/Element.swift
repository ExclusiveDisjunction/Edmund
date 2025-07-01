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
    func update(_ from: Snapshot, unique: UniqueEngine) throws(UniqueFailureError<Self.ID>);
}
/// Represents a class that can be used to hold the values of an element for editing.
public protocol ElementSnapshot: AnyObject, Observable, Hashable, Equatable, Identifiable {
    /// Determines if the current values are acceptable to display to the user.
    func validate(unique: UniqueEngine) async -> ValidationFailure?
}

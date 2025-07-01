//
//  UtilityEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftData
import Foundation

/// A specific charged instance of a utility's costs.
@Model
public class UtilityEntry: Identifiable, Hashable, Equatable, SnapshotableElement, DefaultableElement {
    public required init() {
        self.id = UUID()
        self.amount = 0
        self.date = .now
    }
    public init(_ date: Date, _ amount: Decimal, id: UUID = UUID()) {
        self.date = date
        self.amount = amount
        self.id = id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(amount)
    }
    public static func ==(lhs: UtilityEntry, rhs: UtilityEntry) -> Bool {
        lhs.date == rhs.date && lhs.amount == rhs.amount
    }
    
    public func makeSnapshot() -> UtilityEntrySnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> UtilityEntrySnapshot {
        .init()
    }
    public func update(_ from: UtilityEntrySnapshot, unique: UniqueEngine) {
        self.date = from.date
        self.amount = from.amount.rawValue
    }
    
    public var id: UUID = UUID()
    /// How much the bill cost
    public var amount: Decimal = 0;
    /// The date that the charge occured on
    public var date: Date = Date.now;
    /// The parent utility that this is associated with
    @Relationship
    public var parent: Utility? = nil;
}

/// The snapshot for `UtilityEntry`
@Observable
public class UtilityEntrySnapshot: Identifiable, Hashable, Equatable, ElementSnapshot {
    /// Creates a blank instance of a snapshot.
    public init() {
        self.id = UUID()
        self.amount = .init()
        self.date = .now;
    }
    /// Fills in data from a `UtilityEntry`
    public init(_ from: UtilityEntry) {
        self.id = from.id
        self.amount = .init(rawValue: from.amount)
        self.date = from.date
    }
    
    public var id: UUID;
    /// The associated amount
    public var amount: CurrencyValue;
    /// The date this occured on
    public var date: Date;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        amount < 0 ? .negativeAmount : nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
    }
    public static func ==(lhs: UtilityEntrySnapshot, rhs: UtilityEntrySnapshot) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}

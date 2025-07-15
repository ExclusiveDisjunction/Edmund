//
//  UtilityEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftData
import Foundation

/*
public struct UtilityEntryID : Hashable, Sendable, Equatable, CustomStringConvertible {
    public let index: Int;
    public let parent: BillBaseID?;
    
    public var description: String {
        if let parent = parent {
            "\(parent)-entry:\(index)"
        }
        else {
            "-entry:\(index)"
        }
    }
}

extension EdmundModelsV1 {
    /// A specific charged instance of a utility's costs.
    @Model
    public class UtilityEntry: Identifiable, Hashable, Equatable, SnapshotableElement, UniqueElement {
        public static var objId: ObjectIdentifier {
            .init(UtilityEntry.self)
        }
        
        public init(_ amount: Decimal, index: Int) {
            self.amount = amount
            self.index = index
        }
        
        public var id: UtilityEntryID {
            .init(index: index, parent: parent?.id)
        }
        /// How much the bill cost
        public var amount: Decimal = 0;
        public var index: Int;
        /// The parent utility that this is associated with
        @Relationship
        public var parent: Utility? = nil;
        
        public func makeSnapshot() -> UtilityEntrySnapshot {
            .init(self)
        }
        public static func makeBlankSnapshot() -> UtilityEntrySnapshot {
            .init()
        }
        public func update(_ from: UtilityEntrySnapshot, unique: UniqueEngine) async throws(UniqueFailureError<UtilityEntryID>) {
            fatalError()
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(index)
            hasher.combine(amount)
        }
        public static func ==(lhs: UtilityEntry, rhs: UtilityEntry) -> Bool {
            lhs.index == rhs.index && lhs.amount == rhs.amount
        }
    }
}

public typealias UtilityEntry = EdmundModelsV1.UtilityEntry

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
*/

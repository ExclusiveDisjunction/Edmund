//
//  TraditionalJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import Foundation
import SwiftData

/// A basis for all jobs that Edmund supports.
public protocol JobBase : PersistentModel, Identifiable {
    /// The amount of money taken out as taxes.
    var taxRate: Decimal { get set }
    /// The average gross (pre-tax) amount.
    var grossAmount : Decimal { get }
}
public extension JobBase {
    /// The average amount gained (post-tax).
    var estimatedProfit : Decimal {
        grossAmount * (1 - taxRate)
    }
}

/// An identifer that can be used for any `TraditionalJob`.
public struct TraditionalJobID : Hashable, Equatable, RawRepresentable, Sendable {
    public init(company: String, position: String) {
        self.company = company
        self.position = position
    }
    public init?(rawValue: String) {
        let split = rawValue.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) };
        guard split.count == 2 else { return nil }
        guard !split[0].isEmpty && !split[1].isEmpty else { return nil }
        
        self.company = split[0];
        self.position = split[1];
    }
    
    /// The company the job is with
    public let company: String;
    /// The position/title that you work as
    public let position: String;
    public var rawValue: String {
        "\(company).\(position)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(company)
        hasher.combine(position)
    }
    public static func ==(lhs: TraditionalJobID, rhs: TraditionalJobID) -> Bool {
        lhs.company == rhs.company && lhs.position == rhs.position
    }
}

/// Represents a job that takes place at a company, meaning that there is a company and position that you work.
public protocol TraditionalJob : JobBase, Identifiable<TraditionalJobID> {
    /// The company that is being worked for
    var company: String { get set}
    /// The role that the individual works.
    var position: String  { get set }
}
internal extension TraditionalJob {
    @MainActor
    func updateBase(_ snap: TraditionalJobSnapshot, unique: UniqueEngine) async throws (UniqueFailureError<TraditionalJobID>) {
        let company = snap.company.trimmingCharacters(in: .whitespaces)
        let position = snap.position.trimmingCharacters(in: .whitespaces)
        let id = TraditionalJobID(company: company, position: position)
        
        if id != self.id {
            let couldSwap = await unique.swapId(key: .init((any TraditionalJob).self), oldId: self.id, newId: id)
            guard couldSwap else {
                throw UniqueFailureError(value: id)
            }
        }
        
        self.taxRate = snap.taxRate
        self.company = company
        self.position = position
    }
}

/// Holds an `any TraditionalJob` for use in UI code & logic.
public struct TraditionalJobWrapper : Identifiable {
    public init(_ data: any TraditionalJob, id: UUID = UUID()) {
        self.data = data;
        self.id = id;
    }
    
    /// The targeted data
    public var data: any TraditionalJob;
    public var id: UUID;
}

@Observable
public class JobSnapshot : Hashable, Equatable {
    public init() {
        self.taxRate = 0.00;
    }
    public init<T>(_ from: T) where T: JobBase {
        self.taxRate = from.taxRate;
    }
    
    public var taxRate: Decimal;
    
    public func validate() -> ValidationFailure? {
        if taxRate < 0      { return .negativeAmount }
        else if taxRate > 1 { return .tooLargeAmount }
        
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(taxRate)
    }
    public static func == (lhs: JobSnapshot, rhs: JobSnapshot) -> Bool {
        lhs.taxRate == rhs.taxRate
    }
}

@Observable
public class TraditionalJobSnapshot : JobSnapshot {
    public override init() {
        self.company = "";
        self.position = "";
        self.oldId = .init(company: "", position: "")
        
        super.init()
    }
    public init<T>(_ from: T) where T: TraditionalJob {
        self.company = from.company
        self.position = from.position
        self.oldId = from.id;
        
        super.init(from)
    }
    
    @ObservationIgnored private let oldId: TraditionalJobID;
    
    public var company: String;
    public var position: String;
    
    @MainActor
    public func validate(unique: UniqueEngine) async -> ValidationFailure? {
        let company = self.company.trimmingCharacters(in: .whitespaces)
        let position = self.position.trimmingCharacters(in: .whitespaces)
        let id = TraditionalJobID(company: company, position: position)
        
        if let topResult = super.validate() {
            return topResult
        }
        
        if oldId != id {
            let idOpen = await unique.isIdOpen(key: HourlyJob.objId, id: id)
            guard idOpen else { return .unique }
        }
        
        guard !company.isEmpty && !position.isEmpty else { return .empty }
        
        return nil
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(company)
        hasher.combine(position)
        super.hash(into: &hasher)
    }
    public static func ==(lhs: TraditionalJobSnapshot, rhs: TraditionalJobSnapshot) -> Bool {
        (lhs as JobSnapshot) == (rhs as JobSnapshot) && lhs.company == rhs.company && lhs.position == rhs.position
    }
}

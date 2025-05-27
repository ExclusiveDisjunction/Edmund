//
//  TraditionalJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import Foundation
import SwiftData

/// A basis for all jobs that Edmund supports.
public protocol JobBase : PersistentModel, InspectableElement, EditableElement {
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

/// Represents a job that takes place at a company, meaning that there is a company and position that you work.
public protocol TraditionalJob : JobBase {
    /// The company that is being worked for
    var company: String { get set}
    /// The role that the individual works.
    var position: String  { get set }
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

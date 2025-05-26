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
        grossAmount * taxRate
    }
}

/// Represents a job that takes place at a company, meaning that there is a company and position that you work.
public protocol TraditionalJob : JobBase {
    /// The company that is being worked for
    var company: String { get set}
    /// The role that the individual works.
    var position: String  { get set }
}

//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

/// The bills kind that is used by the Bill class, as it does not include the utility kind.
public enum StrictBillsKind : Int, Equatable, Hashable, Codable, Identifiable, CaseIterable, Sendable {
    case subscription
    case bill
    
    public var id: Self { self }
}

@frozen
public enum BillsKind : Int, Equatable, Codable, Hashable, Comparable, Filterable, Sendable {
    public typealias On = BillBaseWrapper
    
    case bill = 0
    case subscription = 1
    case utility = 2
    
    public var id: Self { self }
    
    public static func <(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum BillsSort : Int, Identifiable, CaseIterable, Sortable, Sendable {
    case name, amount, kind
    
    public var id: Self { self }
}



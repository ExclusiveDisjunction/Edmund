//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI

/// An identifier that can be used for any `BillBase`.
public struct BillID : Hashable, Equatable, RawRepresentable, Sendable, CustomStringConvertible {
    public init(name: String, company: String, location: String?) {
        self.name = name
        self.company = company
        self.location = location
    }
    public init?(rawValue: String) {
        let split = rawValue.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) };
        guard split.count == 3 else { return nil }
        guard !split[0].isEmpty && !split[1].isEmpty else { return nil } //The last part can be empty
        
        self.name = split[0]
        self.company = split[1]
        self.location = split[2].isEmpty ? nil : split[2]
    }
    
    /// The name of the bill
    public let name: String;
    /// The name of the company the bill comes from
    public let company: String;
    /// An optional location where that bill origionates. Think an electric bill.
    public let location: String?;
    public var rawValue: String {
        "\(name).\(company).\(location ?? String())"
    }
    public var description: String {
        let result = "\(name) from \(company)";
        if let location = location {
            return result + " at \(location)"
        }
        else {
            return result
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(company)
        hasher.combine(location)
    }
    public static func ==(lhs: BillID, rhs: BillID) -> Bool {
        lhs.name == rhs.name && lhs.company == rhs.company && lhs.location == rhs.location
    }
}

@frozen
public enum BillsKind : Int, Equatable, Codable, Hashable, Comparable, Filterable, Sendable {
    case bill = 0
    case subscription = 1
    case utility = 2
    
    public var id: Self { self }
    
    public static func <(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
extension BillsKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription"
            case .bill: "Bill"
            case .utility: "Utility"
        }
    }
    
    public var title: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription Payment"
            case .bill: "Bill Payment"
            case .utility: "Utility Payment"
        }
    }
}

public enum BillsSort : Int, Identifiable, CaseIterable, Sortable, Sendable {
    case name, amount, kind
    
    public var id: Self { self }
}
extension BillsSort : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .name: "Name"
            case .amount: "Amount"
            case .kind: "Kind"
        }
    }
}

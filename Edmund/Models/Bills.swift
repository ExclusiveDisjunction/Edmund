//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftData
import Foundation

enum BillsKind : String, CaseIterable, Identifiable, Equatable {
    case simple
    case complex
    
    var id: Self { self }
    func toString() -> String {
        return switch self {
        case .simple: "Simple"
        case .complex: "Complex"
        }
    }
}

enum BillsPeriod: String, CaseIterable, Identifiable, Equatable {
    case weekly
    case monthly
    case triMonthly
    case hexMonthly
    case anually
    
    var timesPerYear: Int {
        switch self {
        case .weekly: 52
        case .monthly: 12
        case .triMonthly: 4
        case .hexMonthly: 2
        case .anually: 1
        }
    }
    static func fromTimesPerYear(_ val: Int) -> BillsPeriod {
        switch val {
        case 52: return .weekly
        case 12: return .monthly
        case 4: return .triMonthly
        case 2: return .hexMonthly
        default: return .anually
        }
    }
    
    var id: Self { self }
    
    func toString() -> String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .triMonthly: "Quarterly"
        case .hexMonthly: "Semi-Annually"
        case .anually: "Annually"
        }
    }
}

@Model
class Bill : Identifiable{
    init(name: String, amount: Decimal, kind: BillsKind, period: BillsPeriod = .monthly) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.isSimple = kind == .simple
        self.timesPerYear = period.timesPerYear
    }
    
    var id: UUID
    @Attribute(.unique) var name: String
    var amount: Decimal;
    var isSimple: Bool;
    
    var kind: BillsKind {
        get {
            self.isSimple ? .simple : .complex
        }
        set(v) {
            self.isSimple = v == .simple
        }
    }
    func kindMatches(_ kind: BillsKind) -> Bool {
        self.kind == kind
    }
    
    private var timesPerYear: Int;
    var period: BillsPeriod {
        get {
            BillsPeriod.fromTimesPerYear(self.timesPerYear)
        }
        set(v) {
            self.timesPerYear = v.timesPerYear
        }
    }
    
    var pricePerWeek: Decimal {
        get {
            switch self.period {
            case .weekly: self.amount
            case .monthly: self.amount / 4
            case .triMonthly: self.amount / 12
            case .hexMonthly: self.amount / 24
            case .anually: self.amount / 52
            }
        }
    }
    
    static var exampleBills: [Bill] {
        [
            .init(name: "Apple Music", amount: 5.99, kind: .simple),
            .init(name: "iCloud", amount: 2.99, kind: .simple),
            .init(name: "YouTube Premium", amount: 9.99, kind: .simple),
            .init(name: "Student Loan", amount: 56, kind: .complex),
            .init(name: "Car Insurance", amount: 899, kind: .complex, period: .hexMonthly)
        ]
    }
}

@Model
class Utility: Identifiable {
    init(name: String, amounts: [Decimal]) {
        self.id = UUID()
        self.name = name
        self.amounts = amounts
    }
    
    var id: UUID;
    @Attribute(.unique) var name: String
    var amounts: [Decimal]
    
    var pricePerWeek: Decimal {
        get {
            let avg = self.amounts.reduce(Decimal(0.0), { $0 + $1 }) / Decimal(self.amounts.count)
            return avg / 4.0;
        }
    }
    
    static var exampleUtilities: [Utility] {
        [
            Utility(name: "Gas", amounts: [25, 23, 28, 27]),
            Utility(name: "Electric", amounts: [30, 31, 38, 36]),
            Utility(name: "Internet", amounts: [34, 25, 35, 35]),
            Utility(name: "Water", amounts: [10, 12, 14, 15])
        ]
    }
}

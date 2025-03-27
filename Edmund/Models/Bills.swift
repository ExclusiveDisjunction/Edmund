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

enum Month: Int, Equatable {
    case jan = 1
    case feb = 2
    case mar = 3
    case apr = 4
    case may = 5
    case jun = 6
    case jul = 7
    case aug = 8
    case sept = 9
    case oct = 10
    case nov = 11
    case dec = 12
    
    static func fromString(_ val: String) -> Month {
        switch val {
        case "January": .jan
        case "February": .feb
        case "March": .mar
        case "April": .apr
        case "May": .may
        case "June": .jun
        case "July": .jul
        case "August": .aug
        case "September": .sept
        case "October": .oct
        case "November": .nov
        case "December": .dec
        default: .dec
        }
    }
    
    func toString() -> String {
        switch self {
        case .jan: "January"
        case .feb: "February"
        case .mar: "March"
        case .apr: "April"
        case .may : "May"
        case .jun: "June"
        case .jul: "July"
        case .aug: "August"
        case .sept: "September"
        case .oct: "October"
        case .nov: "November"
        case .dec: "December"
        }
    }
}

@Model
class UtilityEntry: Identifiable {
    init(_ month: Month, _ amount: Decimal) {
        self.rawMonth = month.rawValue
        self.amount = amount
    }
    
    var id = UUID()
    private var rawMonth: Int;
    var amount: Decimal;
    @Relationship var parent: Utility?;
    
    func getRawMonth() -> Int {
        self.rawMonth
    }
    
    var month: Month {
        get {
            Month(rawValue: self.rawMonth)!
        }
        set(v) {
            self.rawMonth = v.rawValue
        }
    }
}

@Model
class Utility: Identifiable {
    init(name: String, amounts: [UtilityEntry]) {
        self.id = UUID()
        self.name = name
        self.amounts = amounts
    }
    
    var id: UUID;
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .cascade, inverse: \UtilityEntry.parent) var amounts: [UtilityEntry]
    
    var pricePerWeek: Decimal {
        get {
            let avg = self.amounts.reduce(Decimal(0.0), { $0 + $1.amount }) / Decimal(self.amounts.count)
            return avg / 4.0;
        }
    }
    
    static var exampleUtilities: [Utility] {
        [
            Utility(name: "Gas", amounts: [.init(Month.jan, 25),
                                           .init(Month.feb, 23),
                                           .init(Month.mar, 28),
                                           .init(Month.apr, 27)]),
            Utility(name: "Electric", amounts: [.init(Month.jan, 30),
                                                .init(Month.feb, 31),
                                                .init(Month.mar, 38),
                                                .init(Month.apr, 36)]),
            Utility(name: "Internet", amounts: [.init(Month.jan, 34),
                                                .init(Month.feb, 25),
                                                .init(Month.mar, 35),
                                                .init(Month.apr, 35)]),
            Utility(name: "Water", amounts: [.init(Month.jan, 10),
                                             .init(Month.feb, 12),
                                             .init(Month.mar, 14),
                                             .init(Month.apr, 15)])
        ]
    }
}

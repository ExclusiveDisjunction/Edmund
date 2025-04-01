//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftData
import Foundation

enum BillsKind : String, Filterable {
    typealias On = Bill
    
    case subscription = "Subscription"
    case bill = "Bill"
    
    var id: Self { self }
    
    var toString: String {
        self.rawValue
    }
    var toStringPlural: String {
        self.rawValue + "s"
    }
    
    func accepts(_ val: Bill) -> Bool {
        val.kind == self
    }
}
enum BillsSort : String, Sortable {
    typealias On = Bill;
    
    case name = "Name", amount = "Amount", pricePerWeek = "Price Per Week"
    
    var id: Self { self }
    var toString: String {
        self.rawValue
    }
    var ascendingQuestion: String {
        switch self {
            case .name: "Alphabetical?"
            case .amount: "Cheapest First?"
            case .pricePerWeek: "Cheapest First?"
        }
    }
    
    func compare(_ lhs: Bill, _ rhs: Bill, _ ascending: Bool) -> Bool {
        switch self {
            case .name: ascending ? lhs.name < rhs.name : lhs.name > rhs.name
            case .amount: ascending ? lhs.amount < rhs.amount : lhs.amount > rhs.amount
            case .pricePerWeek: ascending ? lhs.pricePerWeek < rhs.pricePerWeek : lhs.pricePerWeek > rhs.pricePerWeek
        }
    }
}

enum BillsPeriod: String, CaseIterable, Identifiable, Equatable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnually = "Semi-Anually"
    case anually = "Anually"
    
    var timesPerYear: Int {
        switch self {
        case .weekly: 52
        case .monthly: 12
        case .quarterly: 4
        case .semiAnually: 2
        case .anually: 1
        }
    }
    static func fromTimesPerYear(_ val: Int) -> BillsPeriod {
        switch val {
        case 52: return .weekly
        case 12: return .monthly
        case 4: return .quarterly
        case 2: return .semiAnually
        default: return .anually
        }
    }
    
    var id: Self { self }
}

@Model
final class Bill : Identifiable, Queryable {
    typealias SortType = BillsSort
    typealias FilterType = BillsKind
    
    init(name: String, amount: Decimal, kind: BillsKind, period: BillsPeriod = .monthly) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.isSubscription = kind == .subscription
        self.timesPerYear = period.timesPerYear
    }
    
    var id: UUID
    @Attribute(.unique) var name: String
    var amount: Decimal;
    var isSubscription: Bool;
    
    var kind: BillsKind {
        get {
            self.isSubscription ? .subscription : .bill
        }
        set(v) {
            self.isSubscription = v == .subscription
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
            case .quarterly: self.amount / 12
            case .semiAnually: self.amount / 24
            case .anually: self.amount / 52
            }
        }
    }
    
    static var exampleBills: [Bill] {
        [
            .init(name: "Apple Music", amount: 5.99, kind: .subscription),
            .init(name: "iCloud", amount: 2.99, kind: .subscription),
            .init(name: "YouTube Premium", amount: 9.99, kind: .subscription),
            .init(name: "Student Loan", amount: 56, kind: .bill),
            .init(name: "Car Insurance", amount: 899, kind: .bill, period: .semiAnually)
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
    
    var asString: String {
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
    var asShortString: String {
        switch self {
            case .jan: "Jan"
            case .feb: "Feb"
            case .mar: "Mar"
            case .apr: "Apr"
            case .may : "May"
            case .jun: "Jun"
            case .jul: "Jul"
            case .aug: "Aug"
            case .sept: "Sept"
            case .oct: "Oct"
            case .nov: "Nov"
            case .dec: "Dec"
        }
    }
}

@Model
class UtilityEntry: Identifiable {
    init(_ date: Date, _ amount: Decimal) {
        self.date = date
        self.amount = amount
    }
    
    var id = UUID()
    var date: Date;
    var amount: Decimal;
    @Relationship var parent: Utility?;
}

@Model
final class Utility: Identifiable { //, Queryable {
    init(name: String, amounts: [UtilityEntry]) {
        self.id = UUID()
        self.name = name
        self.amounts = amounts
    }
    
    //typealias SortType = UtilitySort;
    //typealias FilterType = UtilityFilter;
    
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
            Utility(name: "Gas", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 25))!, 25),
                                           .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 25))!, 23),
                                           .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 25))!, 28),
                                           .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 25))!, 27)]),
            Utility(name: "Electric", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 17))!, 30),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 17))!, 31),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 17))!, 38),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 17))!, 36)]),
            Utility(name: "Internet", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 14))!, 34),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 14))!, 25),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 14))!, 35),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 14))!, 35)]),
            Utility(name: "Water", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 2))!, 10),
                                             .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 2))!, 12),
                                             .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 2))!, 14),
                                             .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 2))!, 15)])
        ]
    }
}

//
//  AccountsInfo.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import Foundation
import SwiftData

public enum TenderType: String, Codable, Identifiable, CaseIterable {
    public var id: Self { self }
    case Checking = "Checking"
    case Savings = "Savings"
    case Credit = "Credit"
    
    public func toString() -> String {
        return self.rawValue;
    }
}
public enum SubTenderType: String, Codable, Identifiable, CaseIterable {
    public var id: Self { self }
    case Need = "Need"
    case Want = "Want"
    case Savings = "String"
    
    public func toString() -> String {
        return self.rawValue;
    }
}

    /*
     public enum TenderTableRow : Identifiable {
         case tender(Tender)
         case subTender(SubTender)
         
         public var id: UUID {
             switch self {
             case .tender(let account): return account.id
             case .subTender(let subAccount): return subAccount.id
             }
         }
         public var name : String {
             switch self {
             case .tender(let account): return account.name
             case .subTender(let subAccount): return subAccount.name
             }
         }
         public var description: String? {
             switch self {
             case .tender(let account): return account.desc
             case .subTender(let subAccount): return subAccount.desc
             }
         }
         public var accTypeString: String {
             switch self {
             case .tender(let account): return account.accType.rawValue
             case .subTender(let subAccount): return subAccount.accType.rawValue
             }
         }
         public func computeCredit() -> Decimal {
              switch self {
              case .tender(let account): return account.computeCredit()
              case .subTender(let subAccount): return subAccount.computeCredit()
              }
          }
         public func computeDebit() -> Decimal {
              switch self {
              case .tender(let account): return account.computeDebit()
              case .subTender(let subAccount): return subAccount.computeDebit()
              }
          }
         public func computeBalance() -> Decimal {
              switch self {
              case .tender(let account): return account.computeBalance()
              case .subTender(let subAccount): return subAccount.computeBalance()
              }
          }
     }
     */

@Model
public class Tender: ObservableObject {
    init(name: String, desc: String? = nil, loc: String? = nil, type: TenderType, subTenders: [SubTender]? = nil) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.loc = loc
        self.accType = type
        self.subTenders = subTenders ?? []
    }
    
    public var id: UUID
    public var name: String
    public var desc: String?
    public var loc: String?
    public var accType: TenderType
    public var uiExpanded: Bool = true
    
    @Relationship(deleteRule: .cascade) var subTenders: [SubTender]?
    
    public func computeCredit() -> Decimal {
        if subTenders?.count ?? 0 == 0 {
            return 0.00
        }
        else {
            var result: Decimal = 0.00
            for entry in subTenders! {
                result += entry.computeCredit()
            }
            
            return result
        }
    }
    public func computeDebit() -> Decimal {
        if subTenders?.count ?? 0 == 0 {
            return 0.00
        }
        else {
            var result: Decimal = 0.00
            for entry in subTenders! {
                result += entry.computeDebit()
            }
            
            return result
        }
    }
    func computeBalance() -> Decimal {
        if subTenders?.count ?? 0 == 0 {
            return 0.00
        }
        else {
            var result: Decimal = 0.00
            for entry in subTenders! {
                result += entry.computeBalance()
            }
            
            return result
        }
    }
}

@Model
public class SubTender {
    init(name: String, desc: String? = nil, type: SubTenderType, ledgers: [Ledger]? = nil) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.accType = type
        self.ledgers = ledgers
    }
    
    public var id: UUID
    public var name: String
    public var desc: String?
    public var accType: SubTenderType
    
    
    @Relationship(inverse: \Tender.subTenders) var parent: Tender?
    @Relationship(inverse: \Ledger.subTender) var ledgers: [Ledger]?
    
    func computeCredit() -> Decimal {
        if ledgers?.count ?? 0 == 0 {
            return 0.00
        }
        else {
            var result: Decimal = 0.00
            for entry in ledgers! {
                result += entry.credits
            }
            
            return result
        }
    }
    func computeDebit() -> Decimal {
        if ledgers?.count ?? 0 == 0 {
            return 0.00
        }
        else {
            var result: Decimal = 0.00
            for entry in ledgers! {
                result += entry.debits
            }
            
            return result
        }
    }
    func computeBalance() -> Decimal {
        if ledgers?.count ?? 0 == 0 {
            return 0.00
        }
        else {
            var result: Decimal = 0.00
            for entry in ledgers! {
                result += entry.balance
            }
            
            return result
        }
    }
}

@Model
public class Category {
    init(id: UUID, name: String, desc: String? = nil, ledgers: [Ledger]? = nil) {
        self.id = id
        self.name = name
        self.desc = desc
        self.ledgers = ledgers
    }
    
    public var id: UUID
    @Attribute(.unique) public var name: String
    public var desc: String?
    
    @Relationship(inverse: \Ledger.category) public var ledgers: [Ledger]?
}

@Model
public class Ledger {
    init(memo: String, credits: Decimal, debits: Decimal, date: Date, notes: String? = nil, subTender: SubTender, category: Category) {
        self.id = UUID()
        self.memo = memo
        self.credits = credits
        self.debits = debits
        self.date = date
        self.notes = notes
        self.subTender = subTender
        self.category = category
    }
    
    @Attribute(.unique) public var id: UUID
    public var memo: String
    public var credits: Decimal
    public var debits: Decimal
    public var balance: Decimal {
        credits - debits
    }
    public var date: Date
    public var notes: String?
    
    @Relationship() public var subTender: SubTender
    @Relationship() public var category: Category
}

extension SubTender {
    public static var exampleSubTenderNoLedger: SubTender {
        SubTender(name: "DI", desc: "Food", type: .Want)
    }
    public static var exampleSubTender: SubTender {
        SubTender(name: "DI", desc: "Food", type: .Want, ledgers: [Ledger.exampleLedger])
    }
    public static var exampleSubTenders: [SubTender] {
        (0...5).map { i in
            SubTender(name: "SubTender \(i)", desc: "Desc \(i)", type: .Want, ledgers: [ Ledger.exampleLedgers[i] ])
        }
    }
    public static var exampleSubTendersNoLedger: [SubTender] {
        (0...5).map { i in
            SubTender(name: "SubTender \(i)", desc: "Desc \(i)", type: .Want)
        }
    }
}
extension Category {
    public static var exampleCategory: Category {
        Category(id: UUID(), name: "Food")
    }
    public static var exampleCategories: [Category] {
        (0...5).map { i in
            Category(id: UUID(), name: "Category \(i)")
        }
    }
}

extension Tender {
    public static var exampleTender: Tender {
        Tender(name: "Checking", desc: "Main Account", loc: "Capital One", type: TenderType.Checking, subTenders: [
            SubTender.exampleSubTender
        ])
    }
    public static var exampleTenders: [Tender] {
        [
            Tender.exampleTender,
            Tender(name: "Savings", desc: "Main Savings", loc:"Captial One", type: TenderType.Savings, subTenders: nil),
            Tender(name: "Savor", desc: "Credit Line", loc: "Capital One", type: .Credit, subTenders: SubTender.exampleSubTenders)
        ]
    }
}
extension Ledger {
    public static var exampleLedger: Ledger {
        Ledger(memo: "Test One", credits: 4, debits: 0, date: Date.now, subTender: SubTender.exampleSubTenderNoLedger, category: Category.exampleCategory)
    }
    public static var exampleLedgers: [Ledger] {
        (0...5).map { i in
            Ledger(memo: "Test \(i)", credits: Decimal(4 + i), debits: 0, date: Date.now, subTender: SubTender.exampleSubTendersNoLedger[i], category: Category.exampleCategories[i])
        }
    }
}

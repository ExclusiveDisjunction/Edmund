//
//  EdmundTests.swift
//  EdmundTests
//
//  Created by Hollan on 3/30/25.
//

import Testing
import Edmund
import Foundation
import EdmundCore

struct MonthYearTesting {
    @Test func monthYearCompute() {
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 1))!;
        let components = MonthYear(date: date)
        
        #expect(components.month == 4 && components.year == 2025)
    }
    
    @Test func transactionsSplitDate() {
        let category = SubCategory.init("", parent: .init(""));
        let account = SubAccount.init("", parent: .init(""))
        
        let entries: [LedgerEntry] = [
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            
                .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 5, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 5, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 5, 1)!, location: "", category: category, account: account),
            
                .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 6, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 6, 1)!, location: "", category: category, account: account),
            
                .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 7, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 7, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 7, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 0, date: Date.fromParts(2025, 7, 1)!, location: "", category: category, account: account),
        ];
        
        let grouped = TransactionResolver.splitByMonth(entries);
        #expect( grouped[MonthYear(2025, 4), default: []].count == 4 )
        #expect( grouped[MonthYear(2025, 5), default: []].count == 3 )
        #expect( grouped[MonthYear(2025, 6), default: []].count == 2 )
        #expect( grouped[MonthYear(2025, 7), default: []].count == 4 )
    }
}

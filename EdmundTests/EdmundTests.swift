//
//  EdmundTests.swift
//  EdmundTests
//
//  Created by Hollan on 3/30/25.
//

import Testing
import Edmund
import EdmundCore
import Foundation

struct DateEstTestCase {
    let start: Date;
    let end: Date?;
    let next: Date?;
}

struct PeriodTestCase {
    init(_ period: BillsPeriod, date: Date = .now) {
        self.period = period;
        
        let period = period.asDuration;
        let plusOne = (period + date)!;
        let plusOneP5 = (1.5 * period + date)!;
        let plusTwo = (2 * period + date)!;
        let minusOne = (period - date)!;
        let minusOneP5 = (1.5 * period + date)!;
        let minusTwo = (2 * period - date)!;
        
        self.case1 = .init(start: plusOne, end: nil, next: plusOne);
        self.case2 = .init(start: plusOne, end: plusTwo, next: plusOne);
        self.case3 = .init(start: minusOne, end: nil, next: date);
        self.case4 = .init(start: minusOne, end: plusOne, next: date);
        self.case5 = .init(start: minusOneP5, end: nil, next: (0.5 * period + date)!);
        self.case6 = .init(start: minusOneP5, end: plusOneP5, next: (0.5 * period + date)!);
        self.case7 = .init(start: minusTwo, end: minusOne, next: nil);
        self.case8 = .init(start: (1.25 * period - date)!, end: (0.75 * period + date)!, next: nil);
    }
    
    let period: BillsPeriod;
    /// s = d + p, e = nil, ne = s
    let case1: DateEstTestCase;
    /// s = d + p, e = s + p , ne = s
    let case2: DateEstTestCase;
    /// s = d -p, e = nil, ne = d
    let case3: DateEstTestCase;
    /// s = d -p, e = d + p, ne = d
    let case4: DateEstTestCase;
    /// s = d - 1.5p, e = nil, ne = d + 0.5p
    let case5: DateEstTestCase;
    /// s = d - 1.5p, e = d + 1.5p, ne = d + 0.5p
    let case6: DateEstTestCase;
    /// s = d - 2p, e = d - p, ne = nil
    let case7: DateEstTestCase;
    /// s = d - 1.25 p, e = d + 0.74p, ne = nil
    let case8: DateEstTestCase;
    
    var cases: [DateEstTestCase] {
        [
            case1,
            case2,
            case3,
            case4,
            case5,
            case6,
            case7,
            case8
        ]
    }
}

struct EdmundTests {
    @Test func longDurationTest() {
        let start = Date.fromParts(2025, 4, 23)!;
        let oneWeek = Date.fromParts(2025, 4, 30)!;
        let oneMonth = Date.fromParts(2025, 5, 23)!;
        let oneYear = Date.fromParts(2026, 4, 23)!;
        
        #expect((LongDuration.weeks(1) + start) == oneWeek);
        #expect((LongDuration.months(1) + start) == oneMonth);
        #expect((LongDuration.years(1) + start) == oneYear);
    }
    
    @Test func billsPredictedDate() async throws {
        let cases = BillsPeriod.allCases.map{ PeriodTestCase($0) };
        
        for testCase in cases {
            for (i, date) in testCase.cases.enumerated() {
                let bill = Bill(bill: "Testcase", amount: 10.00, company: "", start: date.start, end: date.end);
                
                print("\tTesting \(testCase.period), case \(i + 1)");
                #expect(bill.nextBillDate == date.next);
            }
            
            print("Test for \(testCase.period) finished.\n");
        }
    }
    
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

//
//  YearRow.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/18/25.
//

import Foundation

struct YearRowID : Hashable, Equatable, Sendable {
    let parent: UUID;
    let budget: BudgetMonth.ID;
}

struct YearRow : Identifiable {
    let data: BudgetMonth;
    var id: YearRowID;
    var date: MonthYear {
        data.date
    }
    var display: String {
        data.title
    }
}
struct YearSection : Identifiable {
    let year: Int;
    let id: UUID;
    let children: [YearRow];
}

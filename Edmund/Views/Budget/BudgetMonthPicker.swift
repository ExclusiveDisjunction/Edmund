//
//  BudgetMonthPicker.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import SwiftUI
import SwiftData
import EdmundCore

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

struct BudgetMonthPicker : View {
    @Query private var source: [BudgetMonth];
    @State private var id: YearRowID? = nil;
    @Binding var selected: BudgetMonth?;
    
    @State private var cache: [YearSection] = [];
    
    @Environment(\.loggerSystem) private var loggerSystem;
    
    private func refreshFrom(_ data: [BudgetMonth]) {
        var yearDict: [Int : [BudgetMonth]] = [:];
        for month in data {
            var oldList = yearDict[month.date.year] ?? [];
            oldList.append(month)
            yearDict[month.date.year] = oldList;
        }
        
        self.id = nil;
        self.cache = yearDict.map { (key, value) in
            let id = UUID()
            let children = value.map { child in
                YearRow(data: child, id: .init(parent: id, budget: child.id))
            }.sorted(using: KeyPathComparator(\.date))
            
            return YearSection(year: key, id: id, children: children)
        }.sorted(using: KeyPathComparator(\.year))
    }
    private func idChanged(_ newValue: YearRowID?) {
        guard let id = newValue else {
            self.selected = nil
            return
        }
        
        let parentID = id.parent
        let childID = id.budget
        
        guard let parent = cache.first(where: { $0.id == parentID } ) else {
            self.selected = nil
            loggerSystem?.data.warning("An ID for the budget year was provided, but not found.")
            return
        }
        
        guard let child = parent.children.first(where: { $0.data.id == childID } ) else {
            self.selected = nil
            loggerSystem?.data.warning("An id for the budget month was provided, but was not found")
            return
        }
        
        self.selected = child.data
    }
    
    var body: some View {
        Picker("Budget for:", selection: $id) {
            Text("(Select a Month & Year)").tag(nil as YearRowID?)
            
            ForEach(cache) { section in
                Section {
                    ForEach(section.children) { month in
                        Text(month.display).tag(month.id)
                    }
                } header: {
                    Text(section.year, format: .number.grouping(.never))
                }
            }
        }.onChange(of: source) { _, newValue in
            refreshFrom(newValue)
        }.onChange(of: id) { _, newValue in
            idChanged(newValue)
        }.onAppear {
            refreshFrom(source)
        }
    }
}

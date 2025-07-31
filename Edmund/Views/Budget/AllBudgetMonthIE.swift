//
//  AllBudgetMonthIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct BudgetMonthEdit : View {
    @Bindable var snapshot: BudgetMonthSnapshot
    
    var body: some View {
    
    }
}

struct BudgetMonthInspect : View {
    let data: BudgetMonth
    
    var body: some View {
        
    }
}

struct BudgetMonthEditInstance : Identifiable {
    let source: BudgetMonth
    let snapshot: BudgetMonthSnapshot
    let hash: Int
    
    var id : UUID {
        source.id
    }
    var title: String {
        source.title
    }
}

enum BudgetMonthDisplayer : Identifiable {
    case inspect(BudgetMonth)
    case edit(BudgetMonthEditInstance)
    
    var id: UUID {
        switch self {
            case .inspect(let m): m.id
            case .edit(let e): e.id
        }
    }
    
    var title: String {
        switch self {
            case .inspect(let i): i.title
            case .edit(let e): e.title
        }
    }
    
    var isEdit: Bool {
        if case .edit(_) = self {
            return true
        }
        else {
            return false
        }
    }
}

struct AllBudgetMonthIE : View {
    @Query private var budgetMonths: [BudgetMonth];
    
    @State private var cache: [BudgetMonthDisplayer] = [];
    
    private func refresh() {
        cache = budgetMonths.map {
            .inspect($0)
        }
    }
    
    var body: some View {
        List {
            Button("Load More") {
                
            }.buttonStyle(.borderless)
            
            ForEach(cache) { month in
                Section {
                    
                } header: {
                    HStack {
                        Text(month.title)
                            .font(.title2)
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Image(systemName: month.isEdit ? "checkmark" : "pencil")
                        }
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }.disabled(month.isEdit)
                    }
                }
            }
            
            Button("Load More") {
                
            }.buttonStyle(.borderless)
        }.padding()
            .navigationTitle("Budgets")
            .toolbar {
                
            }.onAppear(perform: refresh)
    }
}

#Preview {
    DebugContainerView {
        AllBudgetMonthIE()
    }
}

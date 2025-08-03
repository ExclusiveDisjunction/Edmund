//
//  BudgetMonthInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import EdmundCore
import SwiftUI

struct BudgetMonthIncomeInspect : View {
    var over: BudgetMonthInspectManifest
    @State private var selection: BudgetIncome.ID? = nil;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        Table(over.over.income, selection: $selection) {
            TableColumn("Name", value: \.name)
            TableColumn("Amount") { income in
                Text(income.amount, format: .currency(code: currencyCode))
            }
            TableColumn("Date") { income in
                if let date = income.date {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                }
                else {
                    Text("(No date)")
                        .italic()
                }
            }
        }
    }
}

struct BudgetMonthSpendingInspect : View {
    var over: BudgetMonthInspectManifest
    
    var body: some View {
        if let cache = over.cache {
            
        }
        else {
            VStack {
                Spacer()
                
                Text("Please wait for the calculations to complete")
                ProgressView()
                
                Spacer()
            }
        }
    }
}

struct BudgetMonthSavingsInspect : View {
    var over: BudgetMonthInspectManifest
    
    var body: some View {
        VStack {
            
        }
    }
}

struct BudgetMonthGoalInfo<T> : Identifiable where T: BoundPair, T: TransactionHolder {
    let id: UUID;
}
struct BudgetMonthInspectCache {
    let spending: [BudgetMonthGoalInfo<SubCategory>];
    let savings: [BudgetMonthGoalInfo<SubAccount>];
}

enum BudgetMonthDataStatus<T> {
    case loading
    case error(Date?, Date?)
    case loaded(T)
}

@Observable
class BudgetMonthInspectManifest {
    public init(over: BudgetMonth) {
        self.over = over
        self.cache = cache
    }
    
    let over: BudgetMonth;
    var cache: BudgetMonthInspectCache? = nil;
    
    func refresh() {
        
    }
}

struct BudgetMonthInspect : View {
    init(over: BudgetMonth) {
        self.over = over
        self.manifest = .init(over: over)
    }
    
    var over: BudgetMonth;
    private var manifest: BudgetMonthInspectManifest;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        VStack {
            HStack {
                Text(over.title)
                    .font(.title)
                Spacer()
            }
            
            TabView {
                BudgetMonthIncomeInspect(over: manifest)
                    .tabItem {
                        Text("Income")
                    }
                
                BudgetMonthSpendingInspect(over: manifest)
                    .tabItem {
                        Text("Spending")
                    }
                
                BudgetMonthSavingsInspect(over: manifest)
                    .tabItem {
                        Text("Savings")
                    }
            }
        }
    }
}

#Preview {
    DebugContainerView {
        BudgetMonthInspect(over: try! .getExampleBudget())
            .padding()
    }
}

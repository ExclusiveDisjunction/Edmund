//
//  BudgetMonthInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/2/25.
//

import os
import EdmundCore
import SwiftUI
import SwiftData

struct BudgetMonthInspect : View {
    init(over: BudgetMonth) {
        self.over = over
        self.manifest = .init(over: over)
    }
    
    var over: BudgetMonth;
    private var manifest: BudgetMonthInspectManifest;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.loggerSystem) private var loggerSystem;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        manifest.refresh(context: modelContext, logger: loggerSystem?.data)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(over.title)
                    .font(.title)
                
                Spacer()
                
                Button {
                    refresh()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }.buttonStyle(.borderless)
            }
            
            TabView {
                BudgetMonthIncomeInspect(over: manifest)
                    .tabItem {
                        Text("Income")
                    }
                
                BudgetGoalsInspect(over: manifest, source: \.spending, name: "Category")
                    .tabItem {
                        Text("Spending")
                    }
                    .onTapGesture {
                        if manifest.cache.isLoading {
                            refresh()
                        }
                    }
                
                BudgetGoalsInspect(over: manifest, source: \.savings, name: "Account")
                    .tabItem {
                        Text("Savings")
                    }
                    .onTapGesture {
                        if manifest.cache.isLoading {
                            refresh()
                        }
                    }
            }
            .onAppear {
                refresh()
            }
            
        }
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @Query var budgets: [BudgetMonth];
    BudgetMonthInspect(over: budgets.first!)
        .padding()
}

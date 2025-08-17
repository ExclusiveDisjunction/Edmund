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

struct BudgetIncomeCloseLook : View {
    var source: BudgetIncome;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.dismiss) private var dismiss;
    
#if os(macOS)
    private let minWidth: CGFloat = 70;
    private let maxWidth: CGFloat = 80;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#endif
    
    
    var body: some View {
        VStack {
            HStack {
                Text("Income Close Look")
                    .font(.title2)
                Spacer()
            }
            
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.name)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        if let date = source.date {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                        }
                        else {
                            Text("(No date)")
                                .italic()
                        }
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

struct BudgetMonthIncomeInspect : View {
    var over: BudgetMonthInspectManifest
    @State private var selection: BudgetIncome.ID? = nil;
    @State private var closeLook: BudgetIncome? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        Table(over.over.income, selection: $selection) {
            TableColumn("Name") { income in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(income.name)
                        Spacer()
                        Text(income.amount, format: .currency(code: currencyCode))
                    }.swipeActions(edge: .trailing) {
                        Button {
                            closeLook = income
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }.tint(.green)
                    }
                }
                else {
                    Text(income.name)
                }
            }
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
        .contextMenu(forSelectionType: BudgetIncome.ID.self) { selection in
            Button {
                if let id = selection.first, let target = over.over.income.first(where: { $0.id == id }), selection.count == 1 {
                    self.closeLook = target
                }
            } label: {
                Label("Close Look", systemImage: "magnifyingglass")
            }.disabled(selection.count != 1)
        }
        .sheet(item: $closeLook) { target in
            BudgetIncomeCloseLook(source: target)
        }
    }
}

struct BudgetGoalCloseLook<T> : View where T: BudgetGoal{
    var source: BudgetPresentableData<T>;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.dismiss) private var dismiss;
    
#if os(macOS)
    private let minWidth: CGFloat = 85;
    private let maxWidth: CGFloat = 95;
#else
    private let minWidth: CGFloat = 100;
    private let maxWidth: CGFloat = 110;
#endif
    
    
    var body: some View {
        VStack {
            HStack {
                Text("Goal Close Look")
                    .font(.title2)
                Spacer()
            }
            
            Grid {
                GridRow {
                    Text("Target:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        CompactNamedPairInspect(source.over.association)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Goal:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.over.amount, format: .currency(code: currencyCode))
                        Text(source.over.period.display)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Monthly Goal:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.over.monthlyGoal, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Progress:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.balance, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Money Left:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.freeToSpend, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Over By:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.overBy, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

struct BudgetMonthGoalInspect<T> : View where T: BudgetGoal {
    var over: BudgetMonthInspectManifest;
    var source: KeyPath<BudgetReducedData, [BudgetPresentableData<T>]>
    var name: LocalizedStringKey;
    
    @State private var selection: Set<BudgetPresentableData<T>.ID> = .init();
    @State private var closeLook: BudgetPresentableData<T>? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            Spacer()
            
            Text("Please wait while Edmund does some math")
                .italic()
            ProgressView()
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func errorView(e: BudgetComputationError) -> some View {
        VStack {
            Spacer()
            
            Text("Edmund is not able to present this budget. Please report this issue.")
                .font(.title3)
            
            Divider()
            Text("Details:")
            
            switch e {
                case .invalidBudget(let start, let end):
                    Text("The start and/or end dates of the budget could not be obtained. Values: \(String(describing: start)), \(String(describing: end))")
                case .swiftData(let inner):
                    Text("The transactions could not be obtained from the data store. Inner error: \(inner.localizedDescription)")
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func loadedView(d: BudgetReducedData) -> some View {
        Table(d[keyPath: source], selection: $selection) {
            TableColumn(name) { row in
                if horizontalSizeClass == .compact {
                    VStack {
                        HStack {
                            Text(row.over.amount, format: .currency(code: currencyCode))
                            Text(row.over.period.display)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            CompactNamedPairInspect(row.over.association)
                        }
                    }.swipeActions(edge: .trailing) {
                        Button {
                            closeLook = row
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }.tint(.green)
                    }
                }
                else {
                    CompactNamedPairInspect(row.over.association)
                }
            }
            
            TableColumn("Goal") { row in
                Text(row.over.amount, format: .currency(code: currencyCode))
            }
            TableColumn("Period") { row in
                Text(row.over.period.display)
            }
            
            TableColumn("Monthly Goal") { row in
                Text(row.over.monthlyGoal, format: .currency(code: currencyCode))
            }
            
            TableColumn("Progress") { row in
                Text(row.balance, format: .currency(code: currencyCode))
            }
            
            TableColumn("Money Left") { row in
                Text(row.freeToSpend, format: .currency(code: currencyCode))
            }
            
            TableColumn("Over By") { row in
                Text(row.overBy, format: .currency(code: currencyCode))
            }
        }.contextMenu(forSelectionType: BudgetPresentableData<T>.ID.self) { selection in
            Button {
                if let id = selection.first, let target = d[keyPath: source].first(where: { $0.id == id } ), selection.count == 1 {
                    self.closeLook = target
                }
            } label: {
                Label("Close Look", systemImage: "magnifyingglass")
            }.disabled(selection.count != 1)
        }
        .sheet(item: $closeLook) { element in
            BudgetGoalCloseLook(source: element)
        }
    }
    
    var body: some View {
        switch over.cache {
            case .loading: loadingView
            case .error(let e): errorView(e: e)
            case .loaded(let d): loadedView(d: d)
        }
    }
}

public enum BudgetLoadingState {
    case loading
    case error(BudgetComputationError)
    case loaded(BudgetReducedData)
    
    var isLoading: Bool {
        switch self {
            case .loading: true
            default: false
        }
    }
}

@Observable
class BudgetMonthInspectManifest {
    public init(over: BudgetMonth) {
        self.over = over
    }
    
    let over: BudgetMonth;
    private(set) var cache: BudgetLoadingState = .loading
    
    @MainActor
    public func refresh(context: ModelContext, logger: Logger?) {
        logger?.info("Refresh for \(self.over.date.description) was called.")
        withAnimation {
            self.cache = .loading
        }
        
        do {
            let pipeline = BudgetComputePipeline(over: over, log: logger)
            let result = try pipeline.compute(context: context)
            logger?.info("Budget month computation complete for month year \(self.over.date.description).")
            withAnimation {
                self.cache = .loaded(result)
            }
        }
        catch let e {
            withAnimation {
                self.cache = .error(e)
            }
        }
    }
}

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
                
                BudgetMonthGoalInspect(over: manifest, source: \.spending, name: "Category")
                    .tabItem {
                        Text("Spending")
                    }
                    .onTapGesture {
                        if manifest.cache.isLoading {
                            refresh()
                        }
                    }
                
                BudgetMonthGoalInspect(over: manifest, source: \.savings, name: "Account")
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

#Preview {
    DebugContainerView {
        BudgetMonthInspect(over: try! .getExampleBudget())
            .padding()
    }
}

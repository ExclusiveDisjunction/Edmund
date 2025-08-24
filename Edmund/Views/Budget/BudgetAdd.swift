//
//  BudgetMonthAdd.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/3/25.
//

import EdmundCore
import SwiftUI
import SwiftData

struct BudgetAdd : View {
    enum Month : Int, Displayable, Identifiable, CaseIterable, Hashable, Equatable {
        case january, february, march, april, may, june, july, august, september, october, november, december
        
        var monthValue: Int {
            self.rawValue + 1
        }
        var id: Self { self }
        
        var display: LocalizedStringKey {
            switch self {
                case .january: "January"
                case .february: "February"
                case .march: "March"
                case .april: "April"
                case .may: "May"
                case .june: "June"
                case .july: "July"
                case .august: "August"
                case .september: "September"
                case .october: "October"
                case .november: "November"
                case .december: "December"
            }
        }
    }
    enum ErrorKind : Displayable {
        case invalidYear
        case invalidMonth
        case internalError
        
        var display: LocalizedStringKey {
            switch self {
                case .invalidYear: "Please put in a valid year (after 1900)."
                case .invalidMonth: "Please select a month."
                case .internalError: "internalError"
            }
        }
    }
    
    @Binding var source: BudgetMonth?;
    @Binding var snapshot: BudgetMonthSnapshot?;
    
    @State private var year: Int = 1900;
    @State private var schema: [Month: Bool]? = nil; //Value is true for a month when the
    @State private var month: Month? = nil;
    @State private var isCopying: Bool = false;
    @State private var copyFromID: YearRowID? = nil;
    @State private var copyFrom: BudgetMonth? = nil;
    @State private var error: ErrorKind? = nil;
    @State private var showError: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.loggerSystem) private var loggerSystem;
    
    private func validate() -> ErrorKind? {
        guard year >= 1900 else {
            return .invalidYear
        }
        
        guard let schema = schema else {
            return .internalError
        }
        guard let month = month, !schema[month, default: true] else {
            return .invalidMonth
        }
        
        let date = MonthYear(year, month.monthValue)
        let new: BudgetMonth;
        if let copy = copyFrom, isCopying {
            new = copy.dupliate(date: date)
        }
        else {
            new = .init(date: date)
        }
        
        modelContext.insert(new)
        source = new;
        snapshot = new.makeSnapshot()
        
        loggerSystem?.data.debug("Source has value? \(source != nil), snapshot has value? \(snapshot != nil)")
        
        return nil
    }
    private func submit() {
        if let result = validate() {
            self.error = result
            self.showError = true
        }
        else {
            dismiss()
        }
    }
    private func getSchema(for year: Int) {
        let budgets = (try? modelContext.fetch(
            FetchDescriptor<BudgetMonth>(predicate: #Predicate<BudgetMonth> {
                $0.date.year == year
            })
        )) ?? []
        loggerSystem?.data.info("Fetched \(budgets.count) budgets for the year \(year).")
        
        var newSchema: [Month : Bool] = .init(uniqueKeysWithValues: Month.allCases.map { ($0, false) } );
        
        for budget in budgets {
            guard let month = Month(rawValue: budget.date.month - 1) else {
                loggerSystem?.data.warning("Could not resolve month \(budget.date.month) into a Month value.")
                continue
            }
            
            loggerSystem?.data.debug("For month \(String(describing: month)), a budget is there.")
            newSchema[month] = true
        }
        
        self.schema = newSchema
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Add Budget")
                    .font(.title2)
                
                Spacer()
            }
            
            Form {
                Section {
                    TextField("Year:", value: $year, format: .number.grouping(.never).precision(.integerLength(4)))
                        .onChange(of: year) { _, new in
                            let adjusted: Int;
                            if new <= 1900 {
                                self.year = 1900
                                adjusted = 1900
                            }
                            else {
                                adjusted = new
                            }
                            
                            getSchema(for: adjusted)
                        }
                    
                    if let schema = schema {
                        Picker("Month:", selection: $month) {
                            Text("(Select)").tag(nil as Month?)
                            
                            ForEach(Month.allCases) { month in
                                if !schema[month, default: true] {
                                    Text(month.display).tag(month)
                                }
                                else {
                                    Text(month.display)
                                        .strikethrough()
                                }
                            }
                        }
                    }
                } footer: {
                    Text("For a given year, you can only have one budget per month. If a budget exists for a given month, it cannot be chosen, and will be struck through.")
#if os(macOS)
                        .padding(.bottom)
#endif
                }
                
                Section {
                    Toggle("Copy from another budget", isOn: $isCopying)
                    
                    if isCopying {
                        BudgetPicker(id: $copyFromID, selected: $copyFrom, label: "Copy from:")
                    }
                } footer: {
                    Text("**Note:** If you copy from a budget, the dates from the incomes will not carry over.", comment: "Keep the ** around the Note part")
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }.buttonStyle(.bordered)
                
                Button("Add") {
                    submit()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
            .onAppear {
                self.year = MonthYear.now?.year ?? 2025
            }
            .alert("Error", isPresented: $showError) {
                Button("Ok") {
                    showError = false
                }
            } message: {
                Text(error?.display ?? "internalError")
            }
    }
}

#Preview {
    DebugContainerView {
        BudgetAdd(source: .constant(nil), snapshot: .constant(nil))
    }
}

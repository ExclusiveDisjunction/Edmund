//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

struct GeneralActionsPanel: View {
    var on_add: () -> Void;
    var on_edit: () -> Void;
    var on_delete: () -> Void;
    
    var body: some View {
        HStack {
            Button(action: on_add) {
                Image(systemName: "plus")
            }
            Button(action: on_edit) {
                Image(systemName: "pencil")
            }
            Button(action: on_delete) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
        }
    }
}

enum SortedColumn: String, CaseIterable, Identifiable {
    case name = "Name", amount = "Amount", pricePerWeek = "Price Per Week"
    
    var id: Self { self }
    /// Represents the question that would denote ascending order
    var orderedName: String {
        switch self {
        case .name: "Alphabetical?"
        case .amount: "Cheapest First?"
        case .pricePerWeek: "Cheapest First?"
        }
    }
}

@Observable
class FilterCase: Identifiable {
    init(val: BillsKind) {
        self.id = UUID();
        self.isSelected = true;
        self.val = val
    }
    
    var id: UUID
    var isSelected: Bool
    var val: BillsKind
}

@Observable
class SortingModel : Identifiable {
    var sorting: SortedColumn = .name
    var ascending: Bool = true
    var showingKinds: [FilterCase] = BillsKind.allCases.map { FilterCase(val: $0 ) };
    
    func toggleSort(_ col: SortedColumn) {
        if col == sorting {
            ascending.toggle()
        }
        else {
            sorting = col
            ascending = true
        }
    }
    
    func apply(_ on: [Bill]) -> [Bill] {
        let sorted = on.sorted { lhs, rhs in
            switch sorting {
                case .name: ascending ? lhs.name < rhs.name : lhs.name > rhs.name
                case .amount: ascending ? lhs.amount < rhs.amount : lhs.amount > rhs.amount
                case .pricePerWeek: ascending ? lhs.pricePerWeek < rhs.pricePerWeek : lhs.pricePerWeek > rhs.pricePerWeek
            }
        }
        
        return sorted.filter { item in
            showingKinds.first(where: {$0.val == item.kind && $0.isSelected == true } ) != nil
        }
    }
}

struct SortingHandle : Identifiable{
    @Bindable var model: SortingModel;
    var id = UUID();
}

struct AllBillsViewEdit : View {
    @State var showSheet = false;
    @State private var selectedBill: Bill?;
    @State private var sorting: SortingModel = .init();
    @State private var sortingHandle: SortingHandle?;
    @State private var tableSelected: Bill.ID?;
    
    @Environment(\.modelContext) var modelContext;
        
    @Query private var bills: [Bill]
    private var sortedBills: [Bill] {
        sorting.apply(bills)
    }
    
    private func add_bill() {
        withAnimation {
            let new_bill = Bill(name: "", amount: 0, kind: .subscription)
            modelContext.insert(new_bill)
            selectedBill = new_bill
        }
    }
    private func remove_selected() {
        withAnimation {
            if let resolved = bills.first(where: {$0.id == tableSelected}) {
                modelContext.delete(resolved)
            }
        }
    }
    private func edit_selected() {
        if let resolved = bills.first(where: {$0.id == tableSelected}) {
            self.selectedBill = resolved;
        }
    }
    
    private var totalPPW: Decimal {
        bills.reduce(0, {$0 + $1.pricePerWeek})
    }

    var body: some View {
        VStack {
            Table(self.sortedBills, selection: $tableSelected) {
                TableColumn("Name", value: \Bill.name)
                TableColumn("Kind", value: \.kind.rawValue)
                TableColumn("Amount") { bill in
                    Text(bill.amount, format: .currency(code: "USD"))
                }
                TableColumn("Frequency") { bill in
                    Text(bill.period.rawValue)
                }
                TableColumn("Price per Week") { bill in
                    Text(bill.pricePerWeek, format: .currency(code: "USD"))
                }
            }
            
            HStack {
                Spacer()
                Text("Total Price Per Week:")
                Text(self.totalPPW, format: .currency(code: "USD"))
            }
        }.padding().sheet(item: $selectedBill) { bill in
            BillEditor(bill: bill)
        }.toolbar {
            Button(action: {
                sortingHandle = .init(model: sorting)
            }) {
                Label("Sort & Filter", systemImage: "line.3.horizontal.decrease.circle")
            }.popover(item: $sortingHandle) { sort in
                Grid {
                    GridRow {
                        Text("Sort By")
                        Picker("Sorting Column", selection: sort.$model.sorting) {
                            ForEach(SortedColumn.allCases, id: \.id) { col in
                                Text(col.rawValue).tag(col)
                            }
                        }.labelsHidden()
                    }
                    
                    GridRow {
                        Text(sort.model.sorting.orderedName)
                        Toggle("Ascending", isOn: sort.$model.ascending).labelsHidden()
                    }
                    
                    GridRow {
                        Text("Bill Kinds")
                        List {
                            ForEach(sort.$model.showingKinds) { $kind in
                                Toggle(kind.val.rawValue, isOn: $kind.isSelected)
                            }
                        }.frame(minHeight: 60)
                    }
                }.padding().frame(minWidth: 300)
            }
            GeneralActionsPanel(on_add: add_bill, on_edit: edit_selected, on_delete: remove_selected)
        }.navigationTitle("Bills")
    }
}

#Preview {
    AllBillsViewEdit().modelContainer(ModelController.previewContainer)
}

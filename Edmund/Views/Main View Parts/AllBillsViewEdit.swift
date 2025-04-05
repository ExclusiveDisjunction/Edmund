//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData
import Charts

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

struct AllBillsViewEdit : View {
    enum WarningKind {
        case noneSelected, editMultipleSelected
    }
    
    struct DeletingAction {
        let data: [Bill];
    }

    @State private var selectedBill: Bill?;
    @State private var query: QueryProvider<Bill> = .init(.name);
    @State private var tableSelected = Set<Bill.ID>();
    @State private var showWarning = false;
    @State private var warning: WarningKind = .noneSelected;
    @State private var deletingAction: DeletingAction?;
    @State private var isDeleting: Bool = false;
    @State private var showingChart: Bool = false;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("showcasePeriod") private var rawShowcasePeriod: BillsPeriod?;
    private var showcasePeriod: BillsPeriod {
        rawShowcasePeriod ?? .weekly
    }
    
#if os(macOS)
    private var popoverMinWidth = CGFloat(300)
#else
    private var popoverMinWidth = CGFloat(400)
#endif
    
    @Environment(\.modelContext) var modelContext;
        
    @Query private var bills: [Bill]
    private var sortedBills: [Bill] {
        query.apply(bills)
    }
    
    private func add_bill(_ kind: BillsKind = .bill) {
        withAnimation {
            let new_bill = Bill(name: "", kind: kind, amount: 0, child: kind == .utility ? UtilityBridge(nil) : nil, start: Date.now, end: nil, period: .monthly)
            modelContext.insert(new_bill)
            selectedBill = new_bill
        }
    }
    private func remove_selected() {
        let resolved = bills.filter { tableSelected.contains($0.id) }
        if resolved.count == 0 {
            warning = .noneSelected
            showWarning = true
        }
        else {
            deletingAction = .init(data: resolved)
            isDeleting = true
        }
    }
    private func edit_selected() {
        let resolved = bills.filter { tableSelected.contains($0.id) }
        if resolved.count == 0 {
            warning = .noneSelected
            showWarning = true
        }
        else if resolved.count == 1 {
            selectedBill = resolved.first!
        }
        else {
            warning = .editMultipleSelected
            showWarning = true
        }
    }
    private func remove_specifics(_ id: Set<Bill.ID>) {
        let resolved = bills.filter { id.contains($0.id) }
        if !resolved.isEmpty {
            deletingAction = .init(data: resolved)
            isDeleting = true
        }
    }
    private func toggle_inspector() {
        showingChart.toggle()
    }
    
    private var totalPPP: Decimal {
        bills.reduce(0, {$0 + $1.pricePer(showcasePeriod)})
    }

    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                List {
                    ForEach(self.sortedBills) { bill in
                        HStack {
                            Text(bill.name)
                            Spacer()
                            Text("\(bill.pricePer(showcasePeriod), format: .currency(code: "USD"))/\(showcasePeriod.perName)")
                        }.swipeActions(edge: .trailing) {
                            Button(action: {
                                selectedBill = bill
                            }) {
                                Label("Inspect", systemImage: "info.circle")
                            }.tint(.green)
                            
                            Button(action: {
                                selectedBill = bill
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }.tint(.blue)
                            
                            Button(action: {
                                deletingAction = .init(data: [bill])
                                isDeleting = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }.tint(.red)
                        }
                    }
                }
            }
            else {
                Table(self.sortedBills, selection: $tableSelected) {
                    TableColumn("Name", value: \Bill.name)
                    TableColumn("Kind", value: \.kind.toString)
                    TableColumn("Amount") { bill in
                        Text(bill.amount, format: .currency(code: "USD"))
                    }
                    TableColumn("Frequency") { bill in
                        Text(bill.period.rawValue)
                    }
                    TableColumn("Price per \(showcasePeriod.perName)") { bill in
                        Text(bill.pricePer(showcasePeriod), format: .currency(code: "USD"))
                    }
                }.contextMenu(forSelectionType: Bill.ID.self) { selection in
                    if selection.count == 1 {
                        let first = selection.first!
                        
                        Button(action: {
                            selectedBill = bills.first(where: {$0.id == first} )
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    Button(action: {
                        remove_specifics(selection)
                    }) {
                        Label("Delete", systemImage: "trash").foregroundStyle(.red)
                    }
                }
                #if os(macOS)
                .frame(minWidth: 270)
                #endif
            }
            
            HStack {
                Spacer()
                Text("Total Price Per \(showcasePeriod.perName):")
                Text(self.totalPPP, format: .currency(code: "USD"))
            }
        }.padding().sheet(item: $selectedBill) { bill in
            BillEditor(bill: bill)
        }.toolbar(id: "billsToolbar") {
            ToolbarItem(id: "query", placement: .secondaryAction) {
                QueryButton(provider: query)
            }
            
            ToolbarItem(id: "graph", placement: .secondaryAction) {
                Button(action: toggle_inspector) {
                    Label(showingChart ? "Hide Graph" : "Show Graph", systemImage: "chart.pie")
                }
            }
            
            ToolbarItem(id: "inspect", placement: .secondaryAction) {
                Button(action: {} ) {
                    Label("Inspect", systemImage: "info.circle")
                }
            }
            
            ToolbarItem(id: "general", placement: .primaryAction) {
                ControlGroup {
                    Menu {
                        Button("Bill", action: {
                            add_bill(.bill)
                        })
                        
                        Button("Subscription", action: {
                            add_bill(.subscription)
                        })
                        
                        Button("Utility", action: {
                            add_bill(.utility)
                        })
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    
                    
                    if horizontalSizeClass != .compact {
                        Button(action: edit_selected) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: remove_selected) {
                            Label("Remove", systemImage: "trash").foregroundStyle(.red)
                        }
                    }
                }
            }
            
            
        }.toolbarRole(.editor)
            .navigationTitle("Bills").alert("Warning", isPresented: $showWarning, actions: {
            Button("Ok", action: {
                showWarning = false
            })
        }, message: {
            switch warning {
                case .noneSelected: Text("No bill is selected, please select at least one and try again.")
                case .editMultipleSelected: Text("Cannot edit multiple bills at once. Please only select one bill and try again.")
            }
        }).confirmationDialog("Are you sure you want to delete this bill?", isPresented: $isDeleting, presenting: deletingAction) { action in
            Button {
                for element in action.data {
                    modelContext.delete(element)
                }
            } label: {
                Text("Remove \(action.data.count) \(action.data.count == 1 ? "bill" : "bills")")
            }
            
            Button("Cancel", role: .cancel) {
                deletingAction = nil
            }
        }.sheet(isPresented: $showingChart) {
            Chart(bills.sorted(by: { $0.amount < $1.amount } )) { bill in
                SectorMark(
                    angle: .value(
                        Text(verbatim: bill.name),
                        bill.pricePer(showcasePeriod)
                    )
                ).foregroundStyle(by: .value(
                        Text(verbatim: bill.name),
                        bill.name
                    )
                )
            }.padding()
            #if os(macOS)
                .frame(minHeight: 350)
            #endif
        }
    }
}

#Preview {
    AllBillsViewEdit().modelContainer(Containers.debugContainer)
}

//
//  BudgetIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/10/25.
//

import SwiftUI
import SwiftData
import EdmundCore

enum IncomeDivisionFinalizationError : WarningBasis, CaseIterable, Identifiable {
    case missingData
    case internalError
    case nonZeroVariance
    case alreadyFinalized
    
    var id: Self { self }
    
    var message: LocalizedStringKey {
        switch self {
            case .missingData: "Not all accounts are filled out. Please ensure all devotions, remainders and deposits have their associated account & sub account."
            case .internalError: "internalError"
            case .nonZeroVariance: "There cannot be a remaining balance. Please use all funds so that the balance is zero. Note, you can use the remainder to correct this."
            case .alreadyFinalized: "This income division has already been finalized, and cannot be finalized again."
        }
    }
}

struct AllIncomeDivisionsIE : View {
    private enum Sheets : Identifiable {
        case searching
        case adding
        case graph
        
        var id: Self { self }
    }
    
    @State private var selectedID: IncomeDivision.ID? = nil;
    @State private var selected: IncomeDivision?;
    @State private var editing: IncomeDivisionSnapshot?;
    
    @State private var showDeleteWarning: Bool = false;
    @State private var showSheet: Sheets? = nil;
    @State private var showFinalizeNotice: Bool = false; //Asks if they want to finalize
    
    @Bindable private var warning: ValidationWarningManifest = .init();
    @Bindable private var finalizeWarning: WarningManifest<IncomeDivisionFinalizationError> = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.categoriesContext) private var categoriesContext;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.pagesLocked) private var pagesLocked;
    @Environment(\.loggerSystem) private var loggerSystem;
    
    private var isEditing: Bool {
        editing != nil
    }
    
    private func cancelEdit() {
        withAnimation {
            editing = nil;
        }
    }
   
    
    @MainActor
    private func finalize(_ income: IncomeDivision) {
        guard !income.isFinalized else {
            finalizeWarning.warning = .alreadyFinalized;
            return;
        }
        guard income.variance == 0 else {
            finalizeWarning.warning = .nonZeroVariance;
            return;
        }
        
        guard let categoriesContext = categoriesContext else {
            loggerSystem?.data.error("To create transactions, please bind the categories context to the view's environment")
            finalizeWarning.warning = .internalError
            return;
        }
        
        guard let payAccount = income.depositTo else {
            loggerSystem?.data.error("Expected an account associated with the income division, but none was provided.")
            finalizeWarning.warning = .missingData;
            return;
        }
        
        let payName: String = switch income.kind {
            case .donation: NSLocalizedString("Donation", comment: "")
            case .gift:     NSLocalizedString("Gift", comment: "")
            case .pay:      NSLocalizedString("Pay", comment: "")
            default:        NSLocalizedString("internalError", comment: "")
        }
        let payCategory = categoriesContext.income
        
        let bank = NSLocalizedString("Bank", comment: "");
        
        let pay = LedgerEntry(name: payName, credit: income.amount, debit: 0, date: .now, location: bank, category: payCategory, account: payAccount)
        
        let transfer = LedgerEntry(name: "\(payAccount.name) to Various", credit: 0, debit: income.amount, date: .now, location: bank, category: categoriesContext.transfers, account: payAccount)
        
        var resultingTransactions: [LedgerEntry] = [pay, transfer]
        for devotion in income.allDevotions {
            guard let acc = devotion.account else {
                loggerSystem?.data.error("Unexpected nil value attached to a devotion")
                finalizeWarning.warning = .missingData;
                return;
            }
            
            let amount = switch devotion {
                case .amount(let a): a.amount
                case .percent(let p): p.amount * income.amount
                case .remainder(_): income.remainderValue
                default: Decimal.nan
            }
            
            resultingTransactions.append(
                LedgerEntry(name: "Various to \(acc.name)", credit: amount, debit: 0, date: .now, location: bank, category: categoriesContext.transfers, account: acc)
            )
        }
        
        for trans in resultingTransactions {
            modelContext.insert(trans)
        }
        
        withAnimation {
            income.isFinalized = true
            selectedID = nil
        }
    }
    @MainActor
    private func submitEdit(_ snapshot: IncomeDivisionSnapshot) async {
        guard let selected = selected else {
            loggerSystem?.data.warning("Submit edit was called, but there is no active snapshot or selected budget.")
            return
        }
        
        if let error = snapshot.validate(unique: uniqueEngine) {
            warning.warning = error
            return;
        }
        else {
            await selected.update(snapshot, unique: uniqueEngine)
        }
        
        cancelEdit()
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            Button {
                showSheet = .graph
            } label: {
                Label("Graph", systemImage: "chart.pie")
            }.disabled(selected == nil || isEditing)
        }
        
        ToolbarItem(placement: .secondaryAction) {
            Button {
                if selected?.isFinalized == true {
                    loggerSystem?.data.warning("Finalize called on a previously finalized income division.")
                    return
                }
                
                showFinalizeNotice = true
            } label: {
                Label("Finalize", systemImage: "square.and.arrow.up.badge.checkmark")
            }.disabled(selected == nil || isEditing || selected?.isFinalized == true)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showSheet = .adding;
            } label: {
                Label("Add", systemImage: "plus")
            }.disabled(isEditing)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                if selected?.isFinalized == true {
                    loggerSystem?.data.warning("Edit called on a finalized budget, this will be ignored")
                    return;
                }
                
                guard let budget = selected else {
                    return
                }
                
                if let snap = editing {
                    Task {
                        await submitEdit(snap)
                    }
                }
                else {
                    withAnimation {
                        editing = budget.makeSnapshot()
                    }
                }
            } label: {
                Label(isEditing ? "Save" : "Edit", systemImage: isEditing ? "checkmark" : "pencil")
            }.disabled(selected == nil || selected?.isFinalized == true)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                if isEditing {
                    cancelEdit()
                }
                else {
                    showDeleteWarning = true
                }
            } label: {
                Label(isEditing ? "Cancel" : "Delete", systemImage: isEditing ? "xmark" : "trash")
                    .foregroundStyle(.red)
            }.disabled(selected == nil)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showSheet = .searching;
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }.disabled(isEditing)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack {
            HStack {
                Text("Income Division:")
                
                IncomeDivisionPicker("", selection: $selected, id: $selectedID)
                    .labelsHidden()
                    .disabled(isEditing)
#if os(iOS)
                Spacer()
#endif
            }
            
            Divider()
            
            if let snapshot = editing {
                IncomeDivisionEdit(snapshot)
            }
            else if let budget = selected {
                IncomeDivisionInspect(data: budget)
            }
            else {
                Spacer()
                Text("Select an income division to begin")
                    .italic()
                Spacer()
                
            }
        }
    }
    
    @ViewBuilder
    private var graph: some View {
        if let selected = selected {
            DevotionGroupsGraph(from: selected)
        }
        else {
            VStack {
                Text("internalError")
                Button("Ok", action: { showSheet = nil } )
            }
        }
    }
    
    @ViewBuilder
    private func sheets(_ sheet: Sheets) -> some View {
        switch sheet {
            case .searching: AllIncomeDivisionsSearch(selection: $selectedID)
            case .adding: AddIncomeDivision(editingSnapshot: $editing, selectionID: $selectedID)
            case .graph: graph
        }
    }
    
    private func finalizePressed() {
        if let budget = selected {
            finalize(budget)
        }
        else {
            print("Note: Division finalize was called, but the budget was not selected.")
        }
    }
    private func deletePressed() {
        if let selected = selected {
            withAnimation {
                self.selectedID = nil;
                self.editing = nil;
                
                modelContext.delete(selected)
            }
        }
    }
    
    var body: some View {
        content
            .padding()
            .navigationTitle("Income Division")
            .toolbar(content: toolbarContent)
            .toolbarRole(horizontalSizeClass == .compact ? .automatic : .editor)
            .onChange(of: editing) { _, newValue in
                pagesLocked.wrappedValue = newValue != nil;
            }
            .sheet(item: $showSheet, content: sheets)
            .confirmationDialog("Warning! Finalizing an income division will apply transactions to the ledger. Do you want to continue?", isPresented: $showFinalizeNotice, titleVisibility: .visible) {
                Button("Ok", action: finalizePressed)
                
                Button("Cancel", role: .cancel, action: { showFinalizeNotice = false })
            }
        
            .alert("Error", isPresented: $finalizeWarning.isPresented) {
                Button("Ok") {
                    finalizeWarning.isPresented = false
                }
            } message: {
                Text(finalizeWarning.message ?? "internalError")
            }
        
            .alert("Error", isPresented: $warning.isPresented) {
                Button("Ok") {
                    warning.isPresented = false
                }
            } message: {
                Text(warning.message ?? "internalError")
            }
        
            .alert("Warning!", isPresented: $showDeleteWarning) {
                Button("Ok", action: deletePressed)
                
                Button("Cancel", role: .cancel) {
                    showDeleteWarning = false;
                }
            } message: {
                Text("Deleting an income division will remove all information associated with it. This action cannot be undone. Note: All finalized transactions will still be in the ledger. Do you want to continue?")
            }
            .navigationBarBackButtonHidden(isEditing)
    }
}

#Preview {
    DebugContainerView {
        AllIncomeDivisionsIE()
    }
}

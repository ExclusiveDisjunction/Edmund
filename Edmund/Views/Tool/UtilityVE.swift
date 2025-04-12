//
//  UtilityVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class UtilityEntrySnapshot: Identifiable, Hashable, Equatable {
    init(_ from: UtilityEntry) {
        self.amount = from.amount
        self.date = from.date
        self.id = UUID()
    }
    init(amount: Decimal, date: Date, id: UUID = UUID()) {
        self.id = id
        self.amount = amount
        self.date = date
    }
    init() {
        self.id = UUID()
        self.amount = 0
        self.date = Date.now
    }
    
    var id: UUID;
    var amount: Decimal;
    var date: Date;
    var isSelected: Bool = false;
    
    var isValid: Bool {
        amount >= 0
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
    }
    static func ==(lhs: UtilityEntrySnapshot, rhs: UtilityEntrySnapshot) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}
@Observable
class UtilitySnapshot : Identifiable, Hashable, Equatable {
    init(_ from: Utility) {
        self.id = UUID()
        self.base = .init(from)
        self.children = from.children.map { UtilityEntrySnapshot($0) }
    }
    
    var id: UUID;
    var base: BillBaseSnapshot;
    var children: [UtilityEntrySnapshot];
    
    var amount: Decimal {
        if children.isEmpty {
            return Decimal()
        }
        else {
            return children.reduce(Decimal(), { $0 + $1.amount } ) / Decimal(children.count)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(children)
    }
    static func ==(lhs: UtilitySnapshot, rhs: UtilitySnapshot) -> Bool {
        lhs.base == rhs.base && lhs.children == rhs.children
    }
    
    func validate() -> Bool {
        let children_result = children.reduce(true, { $0 && $1.isValid } )
        let top_result = self.base.isValid
        
        if !children_result {
            self.base.errors.insert(.children)
        }
        
        return children_result && top_result
    }
    
    func apply(_ to: Utility, context: ModelContext) {
        base.apply(to)
        if to.children.hashValue != children.hashValue {
            let oldChildren = to.children;
            for child in oldChildren {
                context.delete(child)
            }
            
            let children = children.map { UtilityEntry($0.date, $0.amount) }
            for child in children {
                context.insert(child)
            }
            to.children = children 
        }
    }
}

struct UtilityEntriesInspect : View {
    var children: [UtilityEntry];
    @State private var selected = Set<UtilityEntry.ID>();
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";

    var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            
            if horizontalSizeClass == .compact {
                List(children, selection: $selected) { child in
                    HStack {
                        Text(child.amount, format: .currency(code: currencyCode))
                        Text("On", comment: "[Amount] on [Date]")
                        Text(child.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            else {
                Table(children, selection: $selected) {
                    TableColumn("Amount") { child in
                        Text(child.amount, format: .currency(code: currencyCode))
                    }
                    TableColumn("Date") { child in
                        Text(child.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }
            .padding()
        #if os(macOS)
            .frame(minHeight: 350)
        #endif
    }
}
struct UtilityEntriesEditRow : View {
    @Bindable var child: UtilityEntrySnapshot
    let currencyCode: String;
    
    var body: some View {
        GridRow {
            Toggle("Select", isOn: $child.isSelected).labelsHidden().toggleStyle(CheckboxToggleStyle())
            TextField("Amount", value: $child.amount, format: .currency(code: currencyCode))
                .labelsHidden()
                .foregroundStyle(child.amount < 0 ? .red : .primary)
            DatePicker("", selection: $child.date, displayedComponents: .date).labelsHidden()
        }
    }
}
struct UtilityEntriesEdit : View {
    @Bindable var snapshot: UtilitySnapshot;
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func remove_selected() {
        snapshot.children.removeAll(where: { $0.isSelected } )
    }
    private func add_new() {
        snapshot.children.append(.init(amount: 0, date: Date.now))
    }
    
    var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            HStack {
                Button(action: add_new) {
                    Label("Add", systemImage: "plus").buttonStyle(.bordered)
                }
                Button(action: remove_selected) {
                    Label("Delete", systemImage: "trash").foregroundStyle(.red).buttonStyle(.bordered)
                }
                Spacer()
            }
            
            ScrollView {
                Grid {
                    GridRow {
                        Text("")
                        Text("Amount")
                        Text("Date")
                    }
                    
                    ForEach(snapshot.children, id: \.id) { child in
                        UtilityEntriesEditRow(child: child, currencyCode: currencyCode)
                    }
                }
            }.frame(minHeight: 300, maxHeight: .infinity)
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

struct UtilityInspect : View {
    @Bindable var bill: Utility;
    @State private var showingSheet = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 80;
    let maxWidth: CGFloat = 85;
#endif
    
    var body: some View {
        Grid {
            BillBaseInspect(target: bill, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                VStack {
                    Text("Price:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Text(bill.amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                    HStack {
                        Button(action: { showingSheet = true } ) {
                            Label("Inspect Datapoints...", systemImage: "info.circle")
                        }
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            LongTextEditWithLabel(value: $bill.notes, minWidth: minWidth, maxWidth: maxWidth)
        }.sheet(isPresented: $showingSheet) {
            UtilityEntriesInspect(children: bill.children)
        }
    }
}

struct UtilityEdit : View {
    @Bindable var snapshot: UtilitySnapshot;
    @State private var showingSheet = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let minWidth: CGFloat = 80;
    let maxWidth: CGFloat = 90;
#else
    let minWidth: CGFloat = 90;
    let maxWidth: CGFloat = 100;
#endif
    
    var body: some View {
        Grid {
            BillBaseEditor(editing: snapshot.base, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                VStack {
                    Text("Price:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        .foregroundStyle(
                            snapshot.base.errors.contains(.children) || snapshot.base.errors.contains(.amount) ? .red : .primary
                        )
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Text(snapshot.amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                    HStack {
                        Button(action: { showingSheet = true } ) {
                            Label("Edit Datapoints...", systemImage: "pencil")
                        }
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            LongTextEditWithLabel(value: $snapshot.base.notes, minWidth: minWidth, maxWidth: maxWidth)
        }.sheet(isPresented: $showingSheet) {
            UtilityEntriesEdit(snapshot: snapshot)
        }
    }
}

struct UtilityVE : View {
    @Bindable private var bill: Utility;
    @State private var editing: UtilitySnapshot?;
    @State private var editHash: Int;
    @State private var showAlert: Bool = false;
    @State private var warningConfirm: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.dismiss) private var dismiss;
    
    init(_ bill: Utility, isEdit: Bool) {
        self.bill = bill
        if isEdit {
            let tmp = UtilitySnapshot(bill)
            self.editing = tmp
            self.editHash = tmp.hashValue
        }
        else {
            self.editing = nil
            self.editHash = 0
        }
    }
    
    var isEdit: Bool {
        get { editing != nil }
    }

    func validate() -> Bool {
        let result = editing?.validate() ?? true
        showAlert = !result
        
        return result
    }
    func apply() {
        if let editing = editing {
            editing.apply(bill, context: modelContext)
        }
    }
    func submit() {
        if validate() {
            dismiss()
        }
    }
    func cancel() {
        dismiss()
    }
    func toggleMode() {
        if editing == nil {
            // Go into edit mode
            editing = .init(bill)
            editHash = editing!.hashValue
            return
        }
        
        // Do nothing if we have an invalid state.
        guard validate() else { return }
        
        if editing?.hashValue != editHash {
            warningConfirm = true
        }
        else {
            self.editing = nil
        }
    }
    
    var body: some View {
        VStack {
            Text(bill.name).font(.title2)
            Button(action: toggleMode) {
                Image(systemName: isEdit ? "info.circle" : "pencil").resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.accent)
#if os(iOS)
                .padding(.trailing)
#endif
            
            Divider().padding([.top, .bottom])
            
            if let editing = editing {
                UtilityEdit(snapshot: editing)
            }
            else {
                UtilityInspect(bill: bill)
            }
            
            HStack {
                Spacer()
                
                if isEdit {
                    Button("Cancel", action: cancel).buttonStyle(.bordered)
                }
                
                Button("Ok", action: isEdit ? submit : cancel).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please correct fields outlined with red.")
        }).confirmationDialog("There are unsaved changes, do you wish to continue?", isPresented: $warningConfirm) {
            Button("Save", action: {
                apply()
                editing = nil
                warningConfirm = false
            })
            
            Button("Discard") {
                editing = nil
                warningConfirm = false
            }
            
            Button("Cancel", role: .cancel) {
                warningConfirm = false
            }
        }
    }
}

#Preview {
    UtilityVE(Utility.exampleUtility[0], isEdit: false).modelContainer(Containers.debugContainer)
}

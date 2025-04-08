//
//  BillEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

@Observable
class BillBaseManifest: Identifiable, Hashable, Equatable {
    init(_ from: any BillBase) {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.endDate
        self.period = from.period
        self.id = UUID()
    }
    
    var id: UUID;
    var name: String;
    var startDate: Date;
    var endDate: Date?;
    var period: BillsPeriod;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
    }
    static func ==(lhs: BillBaseManifest, rhs: BillBaseManifest) -> Bool {
        lhs.name == rhs.name && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate && lhs.period == rhs.period
    }
    
    func apply(_ to: any BillBase) {
        to.name = name
        to.startDate = startDate
        to.endDate = endDate
        to.period = period
    }
}

@Observable
class UtilityEntryManifest: Identifiable, Hashable, Equatable {
    init(_ from: UtilityEntry) {
        self.amount = from.amount
        self.date = from.date
        self.id = UUID()
    }
    init() {
        self.id = UUID()
        self.amount = 0
        self.date = Date.now
    }
    
    var id: UUID;
    var amount: Decimal;
    var date: Date;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
    }
    static func ==(lhs: UtilityEntryManifest, rhs: UtilityEntryManifest) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}
@Observable
class UtilityManifest : Identifiable, Hashable, Equatable {
    init(_ from: Utility) {
        self.id = UUID()
        self.base = .init(from)
        self.children = from.children.map { UtilityEntryManifest($0) }
    }
    
    var id: UUID;
    var base: BillBaseManifest;
    var children: [UtilityEntryManifest];
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(children)
    }
    static func ==(lhs: UtilityManifest, rhs: UtilityManifest) -> Bool {
        lhs.base == rhs.base && lhs.children == rhs.children
    }
    
    func apply(_ to: Utility) {
        base.apply(to)
        to.children = children.map { UtilityEntry($0.date, $0.amount) }
    }
}

@Observable
class BillManifest : Identifiable, Hashable, Equatable {
    init(_ from: Bill) {
        self.id = UUID();
        self.base = .init(from)
        self.amount = from.amount
        self.kind = from.kind
    }
    
    var id: UUID;
    var base: BillBaseManifest;
    var amount: Decimal;
    var kind: BillsKind;

    func apply(_ to: Bill) {
        base.apply(to)
        to.amount = amount
        to.kind = kind
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(amount)
        hasher.combine(kind)
    }
    
    static func ==(lhs: BillManifest, rhs: BillManifest) -> Bool {
        lhs.base == rhs.base && lhs.amount == rhs.amount && lhs.kind == rhs.kind
    }
}

struct UtilityVE : View {
    @Bindable private var bill: Utility;
    @State private var editing: UtilityManifest?;
    @State private var editHash: Int;
    @State private var showAlert: Bool = false;
    
    var isEdit: Bool {
        get { editing != nil }
    }
    
    func submit() {
        
    }
    func cancel() {
        
    }
    func toggleMode() {
        
    }
    
    @ViewBuilder
    private func edit(_ manifest: UtilityManifest) -> some View {
        Grid {
            
        }
    }
    @ViewBuilder
    private func view() -> some View {
        Grid {
            
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
                edit(editing)
            }
            else {
                view()
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
            Text("Please fill in all fields")
        })
    }
}

struct BillEdit : View {
    init(_ edit: BillManifest) {
        self.editing = edit
    }
    
    @Bindable private var editing: BillManifest;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let labelMinWidth: CGFloat = 80;
    let labelMaxWidth: CGFloat = 90;
#else
    let labelMinWidth: CGFloat = 90;
    let labelMaxWidth: CGFloat = 100;
#endif
    
    @ViewBuilder
    private func childrenEditor(_ children: Binding<[UtilityEntryManifest]>) -> some View {
        VStack {
            ScrollView {
                VStack{
                    ForEach(children, id: \.id) { $child in
                        HStack {
                            TextField("Amount", value: Binding(
                                get: { child.amount },
                                set: { child.amount = $0 }
                            ), format: .currency(code: currencyCode))
                            Text("on")
                            DatePicker("Date", selection: Binding(
                                get: { child.date },
                                set: { child.date = $0 }
                            ), displayedComponents: .date).labelsHidden()
                        }.contentShape(Rectangle())
                            .contextMenu {
                                Button("Delete", action: {
                                    children.wrappedValue.removeAll(where: {$0 == child} )
                                })
                            }
                        Divider()
                    }
                }.frame(minHeight: 160, maxHeight: 200)
            }.frame(minHeight: 160).backgroundStyle(.background.tertiary)
            
            HStack {
                Button(action: {
                    children.wrappedValue.append(UtilityEntryManifest())
                }) {
                    Image(systemName: "plus")
                }
                Spacer()
            }
        }
    }
    
    var body: some View {
        Grid {
            GridRow {
                Text("Name:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
            
                HStack {
                    TextField("Name", text: $editing.name).textFieldStyle(.roundedBorder)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Start Date:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("Start", selection: $editing.startDate, displayedComponents: .date).labelsHidden()
                    Spacer()
                }
            }
            
            GridRow {
                Text("Has End Date:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Toggle("Has End Date", isOn: Binding(get: {editing.endDate != nil }, set: { editing.endDate = $0 ? Date.now : nil } ) ).labelsHidden()
                    Spacer()
                }
            }
            
            if let endDate = editing.endDate {
                GridRow {
                    Text("End Date:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("End", selection: Binding(get: { endDate }, set: {editing.endDate = $0 } ), displayedComponents: .date).labelsHidden()
                        
                        Spacer()
                    }
                }
            }
            
            GridRow {
                Text("Frequency:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Picker("Frequency", selection: $editing.period) {
                        ForEach(BillsPeriod.allCases, id: \.id) { period in
                            Text(period.name).tag(period)
                        }
                    }.labelsHidden()
                    Spacer()
                }
            }
            
            GridRow {
                Text("Kind:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Picker("Kind", selection: $editing.kind) {
                        ForEach(BillsKind.allCases, id: \.id) { kind in
                            Text(kind.name).tag(kind)
                        }
                    }.labelsHidden()
                    
                    Spacer()
                }
            }
            
            if var children = editing.children {
                GridRow {
                    Text("Datapoints:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                    childrenEditor(Binding(get: { children }, set: { children = $0 }))
                }
            }
            else {
                GridRow {
                    Text("Amount:").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        TextField("Amount", value: $editing.amount, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

struct BillView : View {
    var bill: Bill;
    
    var body: some View {
        Grid {
            
        }
    }
}

struct BillVE : View {
    init(_ bill: Bill, isEdit: Bool) {
        self.bill = bill
        
        if isEdit {
            let manifest = BillManifest(bill)
            self.editing = manifest
            self.editHash = manifest.hashValue
        }
        else {
            editing = nil
            editHash = 0
        }
    }
    
    @Bindable private var bill: Bill;
    
    @State private var showAlert = false;
    @State private var editHash: Int;
    @State private var editing: BillManifest?;
    @State private var showConfirm: Bool = false;
    
    private var isEdit: Bool {
        editing != nil
    }
    
    @Environment(\.dismiss) private var dismiss;
    
    private func validate() -> Bool {
        if let editing = editing {
            return editing.isValid
        }
        else {
            return true
        }
    }
    private func submit() {
        if validate() {
            if let editing = editing {
                editing.saveTo(bill)
            }
            
            dismiss()
        }
    }
    private func cancel() {
        dismiss()
    }
    private func toggleMode() {
        if let editing = editing {
            if editing.hashValue != editHash {
                showConfirm = true
                return
            }
            
            self.editing = nil
            self.editHash = 0
        }
        else {
            editing = .init(bill)
            editHash = editing!.hashValue
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
                BillEdit(editing)
            }
            else {
                BillView(bill: bill)
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
            Text("Please fill in all fields")
        })
    }
}

#Preview {
    let bill = Bill.exampleUtility[0]
    
    BillVE(bill, isEdit: true).modelContainer(Containers.debugContainer)
}

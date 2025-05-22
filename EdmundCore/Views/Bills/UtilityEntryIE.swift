//
//  UtilityEntryVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import Foundation
import SwiftUI
import SwiftData
import Charts

@Observable
public class UtilityEntrySnapshot: Identifiable, Hashable, Equatable {
    public init(_ from: UtilityEntry) {
        self.amount = .init(from.amount)
        self.date = from.date
        self.id = UUID()
    }
    public init(amount: Decimal, date: Date, id: UUID = UUID()) {
        self.id = id
        self.amount = .init(amount)
        self.date = date
    }
    public init() {
        self.id = UUID()
        self.amount = .init(0)
        self.date = Date.now
    }
    
    public var id: UUID;
    public var amount: CurrencyValue;
    public var date: Date;
    public var isSelected: Bool = false;
    
    public var isValid: Bool {
        amount >= 0
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
    }
    public static func ==(lhs: UtilityEntrySnapshot, rhs: UtilityEntrySnapshot) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}

public struct UtilityEntriesInspect : View {
    public var children: [UtilityEntry];
    @State private var selected = Set<UtilityEntry.ID>();
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public var body: some View {
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
public struct UtilityEntriesEdit : View {
    @Bindable public var snapshot: UtilitySnapshot;
    @State private var selected = Set<UtilityEntry.ID>();
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func remove_selected() {
        snapshot.children.removeAll(where: { selected.contains($0.id) } )
    }
    private func add_new() {
        snapshot.children.append(.init(amount: 0, date: Date.now))
    }
    
    public var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            HStack {
                Button(action: add_new) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                Button(action: remove_selected) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.buttonStyle(.borderless)
                
                #if os(iOS)
                EditButton()
                #endif
            }
            
            if horizontalSizeClass == .compact {
                List($snapshot.children, selection: $selected) { $child in
                    HStack {
                        CurrencyField($child.amount)
                        Text("On", comment: "[Amount] on [Date]")
                        DatePicker("", selection: $child.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                }.frame(minHeight: 300, maxHeight: .infinity)
            }
            else {
                Table($snapshot.children, selection: $selected) {
                    TableColumn("Amount") { $child in
                        CurrencyField($child.amount)
                    }
                    TableColumn("Date") { $child in
                        DatePicker("", selection: $child.date, displayedComponents: .date)
                            .labelsHidden()
                    }
                }.frame(minHeight: 300, maxHeight: .infinity)
                    .contextMenu(forSelectionType: UtilityEntrySnapshot.ID.self) { selection in
                        Button(action: add_new) {
                            Label("Add", systemImage: "plus")
                        }
                        
                        if !selection.isEmpty {
                            Button(action: {
                                withAnimation {
                                    self.snapshot.children.removeAll(where: { selection.contains($0.id)} )
                                }
                            }) {
                                Label("Remove", systemImage: "trans")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}
public struct UtilityEntriesGraph : View {
    public var source: Utility;
    
    private var children: [UtilityEntry] {
        source.children?.sorted(by: { $0.date < $1.date } ) ?? .init()
    }
    
    public var body: some View {
        VStack {
            Text("Price Over Time").font(.title2)
            
            HStack {
                Chart {
                    ForEach(children, id: \.id) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount),
                            series: .value("Name", source.name)
                        )
                    }
                }.frame(minHeight: 250)
                
                Text("Price").rotationEffect(.degrees(90))
            }
            
            Text("Month")
        }
    }
}

#Preview {
    let bill = Utility.exampleUtility[0];
    ScrollView {
        VStack {
            UtilityEntriesGraph(source: bill)
            Divider()
            UtilityEntriesEdit(snapshot: .init(bill))
            Divider()
            UtilityEntriesInspect(children: bill.children ?? [])
        }.padding()
    }
}

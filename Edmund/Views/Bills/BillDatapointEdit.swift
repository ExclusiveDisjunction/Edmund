//
//  UtilityEntryVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI
import Observation
import CoreData

@Observable
public class BillDatapointSnapshot : Identifiable {
    /// Constructs the snapshot using a pre-existing bill datapoint.
    ///
    /// The current instance will be bound from the instance. This means that it can update the instance it came, therefore reducing the number of deletions.
    public init(from: BillDatapoint, date: Date? = nil) {
        self.boundId = from.objectID;
        self.id = UUID();
        self.amount = from.amount ?? Decimal()
        self.isSkipped = from.amount == nil;
        self.date = date;
    }
    /// Creates a new snapshot from no source data.
    ///
    /// This represents an instance that is not bound from a specific Core Data ``NSManagedObject``. Therefore, after the update, it must be added to the context.
    public init(isSkipped: Bool, date: Date? = nil) {
        self.boundId = nil;
        self.id = UUID();
        self.amount = Decimal();
        self.isSkipped = isSkipped;
        self.date = date;
    }
    
    @ObservationIgnored public let boundId: NSManagedObjectID?;
    @ObservationIgnored public let id: UUID;
    public var amount: Decimal;
    public var isSkipped: Bool;
    public var date: Date?;
    
    public var trueAmount: Decimal? {
        get {
            self.isSkipped ? nil : self.amount
        }
        set {
            if let newValue = newValue {
                self.amount = newValue;
                self.isSkipped = false;
            }
            else {
                self.isSkipped = true;
            }
        }
    }
}


public struct BillDatapointEdit : View {
    public init(bill: Bill) {
        self.bill = bill;
        
        self.history = bill.history.map { BillDatapointSnapshot(from: $0) }
    }
    
    private let bill: Bill;
    @State private var history: [BillDatapointSnapshot];
    @State private var markedForDeletion: [NSManagedObjectID] = [];
    @State private var selected = Set<BillDatapointSnapshot.ID>();
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.calendar) private var calendar;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func addNew(skipped: Bool) {
        let new = BillDatapointSnapshot(isSkipped: skipped);
        
        withAnimation {
            history.append(new)
            adjustDates()
        }
    }
    private func deleteSelected(selection: Set<UUID>? = nil) {
        let selected = selection ?? self.selected;
        
        let targets = history.filter { selected.contains($0.id) };
        
        // Remove the instances
        withAnimation {
            history.removeAll(where: { selected.contains($0.id) } );
            adjustDates()
        }
        
        //Now to ensure that we remove the instances from the store, if they have associated IDs, we msut filter through.
        for target in targets {
            guard let id = target.boundId else {
                continue;
            }
            
            markedForDeletion.append(id);
        }
    }
    
    private func adjustDates() {
        var walker = TimePeriodWalker(start: bill.startDate, end: bill.endDate, period: bill.period, calendar: calendar)
        
        history.forEach {
            $0.date = walker.step()
        }
    }
    
    private func submit() {
        fatalError()
    }
    
    @ViewBuilder
    private var header: some View {
        Text("Payment History").font(.title2)
        
        HStack {
            Menu {
                Button("Add New") {
                    addNew(skipped: false)
                }
                
                Button("Add Skipped") {
                    addNew(skipped: true)
                }
            } label: {
                Image(systemName: "plus")
            }.menuStyle(.borderlessButton)
            
            Button {
                deleteSelected()
            } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }.buttonStyle(.borderless)
            
#if os(iOS)
            EditButton()
#endif
        }
    }
    
    #if os(macOS)
    private var content: some View {
        Table($history, selection: $selected) {
            TableColumn("Amount") { $datapoint in
                if datapoint.isSkipped {
                    Text("Skipped")
                        .italic()
                }
                else {
                    CurrencyField($datapoint.amount, currencyCode: currencyCode)
                }
            }
            
            TableColumn("Skip?") { $datapoint in
                Toggle("", isOn: $datapoint.isSkipped)
                    .labelsHidden()
            }
            
            TableColumn("Date") { $datapoint in
                if let date = datapoint.date {
                    Text(date.formatted(date: .numeric, time: .omitted))
                }
                else {
                    Text("(No Date)")
                        .italic()
                        .foregroundStyle(.red)
                }
            }
        }
    }
    #else
    private var content: some View {
        List(selection: $selected) {
            ForEach($history) { $datapoint in
                HStack {
                    if datapoint.isSkipped {
                        Text("Skipped")
                            .italic()
                    }
                    else {
                        CurrencyField($datapoint.amount, currencyCode: currencyCode)
                    }
                    
                    Spacer()
                    
                    if let date = datapoint.date {
                        Text(date.formatted(date: .numeric, time: .omitted))
                    }
                    else {
                        Text("(No date)")
                            .italic()
                            .foregroundStyle(.red)
                    }
                }.swipeActions(edge: .leading) {
                    Button(datapoint.isSkipped ? "Unskip" : "Skip" ) {
                        datapoint.isSkipped.toggle()
                    }.tint(.blue)
                }
            }.onDelete { offset in
                withAnimation {
                    history.remove(atOffsets: offset)
                    adjustDates()
                }
            }.onMove { index, offset in
                history.move(fromOffsets: index, toOffset: offset)
                
                withAnimation {
                    adjustDates()
                }
            }
        }
    }
    #endif
    
    public var body: some View {
        VStack {
            header
            
            content
                .frame(minHeight: 140, idealHeight: 200, maxHeight: nil)
                .contextMenu(forSelectionType: UUID.self) { selection in
                    if let firstId = selection.first,
                       selection.count == 1,
                       let target = history.first(where: { $0.id == firstId } ) {
                        Button(target.isSkipped ? "Unskip" : "Skip") {
                            target.isSkipped.toggle()
                        }
                    }
                    
                    Button {
                        deleteSelected(selection: selection)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Discard Changes") {
                    dismiss()
                }.buttonStyle(.bordered)
                
                Button("Ok", action: submit ).buttonStyle(.borderedProminent)
            }
        }.padding()
            .onAppear() {
                withAnimation {
                    adjustDates()
                }
            }
    }
}


#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<Bill>(sortDescriptors: []) var bills: FetchedResults<Bill>;
    
    BillDatapointEdit(bill: bills[0])
}

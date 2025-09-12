//
//  UtilityEntryVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI
import SwiftData
import EdmundCore

/// The editor view for Utility Entries.  This provides the layout for editing the entries as a series of payments & dates.
public struct BillHistoryEdit : View {
    public init(snapshot: BillBaseSnapshot) {
        self.snapshot = snapshot
    }
    
    @Bindable public var snapshot: BillBaseSnapshot;
    @State private var selected = Set<UUID>();
    #if os(iOS)
    @State private var showPopover = false;
    #endif
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.calendar) private var calendar;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func add_new(skipped: Bool) {
        let new = BillHistorySnapshot(date: nil);
        new.skipped = skipped;
        
        withAnimation {
            snapshot.history.append(
                new
            )
            adjustDates()
        }
    }
    private func deleteSelected() {
        withAnimation {
            snapshot.history.removeAll(where: { selected.contains($0.id) } )
            
            adjustDates()
        }
    }
    
    private func adjustDates() {
        var walker = TimePeriodWalker(start: snapshot.startDate, end: snapshot.hasEndDate ? snapshot.endDate : nil, period: snapshot.period, calendar: calendar)
        
        snapshot.history.forEach {
            $0.date = walker.step()
        }
    }
    
    @ViewBuilder
    private var form: some View {
        Form {
            DatePicker("Start Date:", selection: $snapshot.startDate, displayedComponents: .date)
            Toggle("Has End Date", isOn: $snapshot.hasEndDate)
            
            if snapshot.hasEndDate {
                DatePicker("End Date:", selection: $snapshot.endDate, displayedComponents: .date)
            }
            
            
            Picker("Frequency:", selection: $snapshot.period) {
                ForEach(TimePeriods.allCases) { period in
                    Text(period.display).tag(period)
                }
            }
        }
        #if os(iOS)
        .frame(minWidth: 250, minHeight: 300)
        #endif
    }
    
    public var body: some View {
        VStack {
            Text("Charge History").font(.title2)
            
#if os(macOS)
            form
#endif
            
            HStack {
#if os(iOS)
                Menu {
                    Button {
                        add_new(skipped: false)
                    } label: {
                        Text("Add")
                    }
                    
                    Button {
                        add_new(skipped: true)
                    } label: {
                        Text("Add Skipped")
                    }
                } label: {
                    Image(systemName: "plus")
                }.menuStyle(.borderlessButton)
#endif
#if os(macOS)
                Button {
                    add_new(skipped: false)
                } label: {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                
                Button(action: deleteSelected) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.buttonStyle(.borderless)
#endif
                
#if os(iOS)
                Divider()
                    .frame(maxHeight: 20)
                Button(action: { showPopover = true } ) {
                    Label("Adjust Dates", systemImage: "pencil")
                }.popover(isPresented: $showPopover) {
                    form
                }
                
                
                EditButton()
#endif
            }
            
#if os(iOS)
            List(selection: $selected) {
                ForEach($snapshot.history) { $child in
                    HStack {
                        if child.skipped {
                            Text("Skipped")
                                .italic()
                        }
                        else {
                            CurrencyField(child.amount)
                        }
                        
                        Spacer()
                        
                        if let date = child.date {
                            Text(date.formatted(date: .numeric, time: .omitted))
                        }
                        else {
                            Text("(No date)")
                                .italic()
                                .foregroundStyle(.red)
                        }
                    }
                }.onDelete { offset in
                    withAnimation {
                        snapshot.history.remove(atOffsets: offset)
                        adjustDates()
                    }
                }.onMove { index, offset in
                    snapshot.history.move(fromOffsets: index, toOffset: offset)
                    
                    withAnimation {
                        adjustDates()
                    }
                }
            }.frame(minHeight: 140, idealHeight: 300, maxHeight: nil)
                .contextMenu(forSelectionType: UUID.self) { selection in
                    Button {
                        withAnimation {
                            snapshot.history.filter { selection.contains($0.id) }.forEach {
                                $0.skipped.toggle()
                            }
                        }
                    } label: {
                        Label("Toggle Skipped", systemImage: "xmark")
                    }
                    
                    Button {
                        withAnimation {
                            snapshot.history.removeAll(where: { selection.contains($0.id) } )
                            
                            adjustDates()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            
#else
            
            Table($snapshot.history, selection: $selected) {
                TableColumn("Amount") { $child in
                    if child.skipped {
                        Text("Skipped")
                            .italic()
                    }
                    else {
                        CurrencyField(child.amount)
                    }
                }
                
                TableColumn("Skip?") { $child in
                    Toggle("", isOn: $child.skipped)
                        .labelsHidden()
                }
                
                TableColumn("Date") { $child in
                    if let date = child.date {
                        Text(date.formatted(date: .numeric, time: .omitted))
                    }
                    else {
                        Text("(No date)")
                            .italic()
                            .foregroundStyle(.red)
                    }
                }
            }.frame(minHeight: 140, idealHeight: 200, maxHeight: 250)
                .contextMenu(forSelectionType: UUID.self) { selection in
                    Button {
                        withAnimation {
                            snapshot.history.removeAll(where: { selection.contains($0.id) } )
                            
                            adjustDates()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            
#endif
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }.padding()
            .onChange(of: snapshot.startDate) { _, _ in
                withAnimation {
                    adjustDates()
                }
            }.onChange(of: snapshot.endDate) { _, _ in
                withAnimation {
                    adjustDates()
                }
            }.onChange(of: snapshot.period) { _, _ in
                withAnimation {
                    adjustDates()
                }
            }
            .onAppear() {
                withAnimation {
                    adjustDates()
                }
            }
    }
}


#Preview {
    BillHistoryEdit(snapshot: .init( Utility.exampleUtility[0] ))
}

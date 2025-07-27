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
public struct UtilityEntriesEdit : View {
    public init(snapshot: UtilitySnapshot) {
        self.snapshot = snapshot
    }
    
    @Bindable public var snapshot: UtilitySnapshot;
    @State private var selected = Set<UUID>();
    #if os(iOS)
    @State private var showPopover = false;
    #endif
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.calendar) private var calendar;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func add_new() {
        withAnimation {
            snapshot.points.append(
                .init(amount: .init(), date: nil)
            )
            adjustDates()
        }
        //snapshot.children.removeAll(where: { selected.contains($0.id) } )
    }
    private func deleteSelected() {
        withAnimation {
            snapshot.points.removeAll(where: { selected.contains($0.id) } )
            
            adjustDates()
        }
    }
    
    private func adjustDates() {
        var walker = TimePeriodWalker(start: snapshot.startDate, end: snapshot.hasEndDate ? snapshot.endDate : nil, period: snapshot.period, calendar: calendar)
        
        snapshot.points.forEach {
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
            Text("Utility Charges").font(.title2)
            
            #if os(macOS)
            form
            #endif
            
            HStack {
                Button(action: add_new) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
#if os(macOS)
                Button(action: deleteSelected) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.buttonStyle(.borderless)
#endif
                
#if os(iOS)
                Button(action: { showPopover = true } ) {
                    Image(systemName: "pencil")
                }.popover(isPresented: $showPopover) {
                    form
                }
                
                
                EditButton()
#endif
            }
            
            List(selection: $selected) {
                ForEach($snapshot.points) { $child in
                    HStack {
                        CurrencyField(child.amount)
                        
                        Spacer()
                        
                        Text("on")
                        if let date = child.date {
                            Text(date.formatted(date: .numeric, time: .omitted))
                        }
                        else {
                            Text("(No date)")
                                .italic()
                                .foregroundStyle(.red)
                        }
                    }
                }.onDelete { set in
                    withAnimation {
                        snapshot.points.remove(atOffsets: set)
                        adjustDates()
                    }
                }.onMove { set, offset in
                    snapshot.points.move(fromOffsets: set, toOffset: offset)
                    
                    withAnimation {
                        adjustDates()
                    }
                }
            }.onChange(of: snapshot.startDate) { _, _ in
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
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}


#Preview {
    UtilityEntriesEdit(snapshot: .init( Utility.exampleUtility[0] ))
}

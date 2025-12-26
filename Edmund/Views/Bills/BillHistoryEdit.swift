//
//  UtilityEntryVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI
import SwiftData

public struct BillHistoryEdit : View {
    public init(snapshot: Bill) {
        self._snapshot = .init(wrappedValue: snapshot)
    }
    
    @StateObject public var snapshot: Bill;
    @State private var selected = Set<BillDatapoint.ID>();
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.calendar) private var calendar;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func addNew(skipped: Bool) {
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
    public var body: some View {
        VStack {
            Text("Payment History").font(.title2)
            
            HStack {
                Menu {
                    Button {
                        addNew(skipped: false)
                    } label: {
                        Text("Add")
                    }
                    
                    Button {
                        addNew(skipped: true)
                    } label: {
                        Text("Add Skipped")
                    }
                } label: {
                    Image(systemName: "plus")
                }.menuStyle(.borderlessButton)
                
                Button(action: deleteSelected) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.buttonStyle(.borderless)
                
#if os(iOS)
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
    BillHistoryEdit(snapshot: .init( Bill.exampleBills[0] ))
}

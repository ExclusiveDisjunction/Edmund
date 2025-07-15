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
    
    /*
    /// Creates the context menu used for the list and table elements of the view.
    @ViewBuilder
    private func selectionContextMenu(_ selection: Set<UtilityEntrySnapshot.ID>) -> some View {
        Button(action: add_new) {
            Label("Add", systemImage: "plus")
        }
        
        if !selection.isEmpty {
            Button(action: {
                withAnimation {
                    //self.snapshot.children.removeAll(where: { selection.contains($0.id)} )
                }
            }) {
                Label("Remove", systemImage: "trans")
                    .foregroundStyle(.red)
            }
        }
    }
     */
    
    private func adjustDates() {
        var walker = TimePeriodWalker(start: snapshot.startDate, end: snapshot.endDate, period: snapshot.period, calendar: calendar)
        
        snapshot.points.forEach {
            $0.date = walker.step()
        }
    }
    
    public var body: some View {
        VStack {
            Text("Utility Charges").font(.title2)
            HStack {
                Button(action: add_new) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                Button(action: {}) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.buttonStyle(.borderless)
                
                #if os(iOS)
                EditButton()
                #endif
            }
            
            List($snapshot.points, editActions: [.delete, .move], selection: $selected) { $child in
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
                    }
                }
            }
            .onChange(of: snapshot.points) { _, _ in
                adjustDates()
            }.onChange(of: snapshot.startDate) { _, _ in
                adjustDates()
            }.onChange(of: snapshot.endDate) { _, _ in
                adjustDates()
            }.onChange(of: snapshot.period) { _, _ in
                adjustDates()
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

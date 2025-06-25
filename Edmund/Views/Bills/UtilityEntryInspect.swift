//
//  UtilityEntryInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

/// The inspection view for Utility Entries.  This provides the layout for viewing all datapoints.
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

#Preview {
    UtilityEntriesInspect(children: Utility.exampleUtility[0].children ?? [])
        .padding()
}

//
//  AllExpiredBillsVE.swift
//  Edmund
//
//  Created by Hollan on 4/5/25.
//

import SwiftUI

struct AllExpiredBillsVE : View {
    @Bindable private var inspect: InspectionManifest<Bill> = .init()
    @Bindable private var delete: DeletingManifest<Bill> = .init()
    @Bindable private var warning: SelectionWarningManifest = .init()
    
    @State private var sorting = [
        SortDescriptor(\Bill.name),
        SortDescriptor(\Bill.kind),
        SortDescriptor(\Bill.period)
    ];
    @State private var searchString = "";
    
    @FilterableQuerySelection<Bill>(filtering: { $0.isExpired } ) private var query;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
   
    @ViewBuilder
    private var empty: some View {
        VStack {
            Spacer()
            Text("There are no expired bills").italic()
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    public func toolbar() -> some ToolbarContent {
        ElementInspectButton(context: query, inspect: inspect, warning: warning, placement: horizontalSizeClass == .compact ? .secondaryAction : .primaryAction)
        ElementEditButton(context: query, inspect: inspect, warning: warning, placement: horizontalSizeClass == .compact ? .secondaryAction : .primaryAction)
        ElementDeleteButton(context: query, delete: delete, warning: warning, placement: .primaryAction)
        
#if os(iOS)
        ToolbarItem(placement: .primaryAction) {
            EditButton()
        }
#endif
    }
    
    @ViewBuilder
    private var regular: some View {
        if query.data.isEmpty {
            empty
        }
        else {
            Table(context: query, sortOrder: $sorting) {
                TableColumn("Name") { wrapper in
                    if horizontalSizeClass == .compact {
                        HStack {
                            Text(wrapper.name)
                            Spacer()
                            Text("Ended:", comment: "Bill ended on date")
                            if let end = wrapper.endDate {
                                Text(end.formatted(date: .numeric, time: .omitted))
                            }
                            else {
                                Text("No Information").italic()
                            }
                        }.swipeActions(edge: .trailing) {
                            SingularContextMenu(wrapper, inspect: inspect, remove: delete, asSlide: true)
                        }
                    }
                    else {
                        Text(wrapper.name)
                    }
                }
                TableColumn("Kind") { wrapper in
                    Text(wrapper.kind.display)
                }
                TableColumn("Started On") { wrapper in
                    Text(wrapper.startDate.formatted(date: .abbreviated, time: .omitted))
                }
                TableColumn("Ended On") { wrapper in
                    if let end = wrapper.endDate {
                        Text(end.formatted(date: .abbreviated, time: .omitted))
                    }
                    else {
                        Text("No Information").italic()
                    }
                }
#if os(iOS)
                TableColumn("Amount") { wrapper in
                    HStack {
                        Text(wrapper.data.amount, format: .currency(code: currencyCode))
                        Text("/")
                        Text(wrapper.data.period.perName)
                    }
                }
#else
                TableColumn("Amount") { wrapper in
                    Text(wrapper.amount, format: .currency(code: currencyCode))
                }
                TableColumn("Frequency") { wrapper in
                    Text(wrapper.period.display)
                }
#endif
            }.contextMenu(forSelectionType: Bill.ID.self) { selection in
                SelectionContextMenu(context: query, inspect: inspect, delete: delete, warning: warning)
            }
            #if os(macOS)
            .frame(minWidth: 350)
            #endif
        }
    }
    
    var body: some View {
        regular
            .navigationTitle("Expired Bills")
            .toolbar(content: toolbar)
            .withElementIE(manifest: inspect, filling: { _ in })
            .withWarning(warning)
            .withElementDeleting(manifest: delete)
            .padding()
            .toolbarRole(ToolbarRole.editor)
    }
}

#Preview(traits: .sampleData) {
    AllExpiredBillsVE()
}

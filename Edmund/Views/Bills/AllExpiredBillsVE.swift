//
//  AllExpiredBillsVE.swift
//  Edmund
//
//  Created by Hollan on 4/5/25.
//

import SwiftUI
import SwiftData

struct AllExpiredBillsVE : View {
    @Query private var bills: [Bill];
    @Bindable private var query: QueryManifest<Bill> = .init(.name)
    @Bindable private var inspect: InspectionManifest<Bill> = .init()
    @Bindable private var deleting: DeletingManifest<Bill> = .init()
    @Bindable private var warning: SelectionWarningManifest = .init()
    @State private var selection =  Set<Bill.ID>();
    @State private var sorting = [
        SortDescriptor(\Bill.name),
        SortDescriptor(\Bill.kind),
        SortDescriptor(\Bill.period)
    ];
    @State private var searchString = "";
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public init() {
        let today = Date.now;
        let future = Date.distantFuture;
        
        _bills = Query(
            filter: #Predicate<Bill> { bill in
                (bill.endDate ?? future) <= today //&& bill.name.caseInsensitiveCompare(searchString) == ComparisonResult.orderedAscending
            },
            sort: sorting
        )
    }
   
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
        ToolbarItem(placement: .secondaryAction) {
            QueryButton(provider: query)
        }
        
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: query.cached, selection: $selection, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
            GeneralIEToolbarButton(on: query.cached, selection: $selection, inspect: inspect, warning: warning, role: .inspect, placement: .primaryAction)
        }
        
        GeneralDeleteToolbarButton(on: query.cached, selection: $selection, delete: deleting, warning: warning, placement: .primaryAction)
        
#if os(iOS)
        ToolbarItem(placement: .primaryAction) {
            EditButton()
        }
#endif
    }
    
    @ViewBuilder
    private var regular: some View {
        if query.cached.isEmpty {
            empty
        }
        else {
            Table(query.cached, selection: $selection, sortOrder: $sorting) {
                TableColumn("Name", sortUsing: SortDescriptor(\.name)) { wrapper in
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
                            SingularContextMenu(wrapper, inspect: inspect, remove: deleting, asSlide: true)
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
                    Text(wrapper.period.perName)
                }
#endif
            }.contextMenu(forSelectionType: Bill.ID.self) { selection in
                SelectionContextMenu(selection, data: query.cached, inspect: inspect, delete: deleting, warning: warning)
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
            .sheet(item: $inspect.value) { item in
                ElementIE(item, mode: inspect.mode)
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok") {
                    warning.isPresented = false
                }
            }, message: {
                Text((warning.warning ?? .noneSelected).message)
            })
            .confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting, titleVisibility: .visible) {
                DeletingActionConfirm(deleting)
            }.padding()
                .toolbarRole(horizontalSizeClass == .compact ? .automatic : .editor)
    }
}

#Preview {
    DebugContainerView {
        NavigationStack {
            AllExpiredBillsVE()
        }
    }
}

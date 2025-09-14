//
//  AllExpiredBillsVE.swift
//  Edmund
//
//  Created by Hollan on 4/5/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct AllExpiredBillsVE : View {
    @Query private var bills: [Bill];
    @Query private var utilities: [Utility];
    @Bindable private var query: QueryManifest<BillBaseWrapper> = .init(.name)
    @Bindable private var inspect: InspectionManifest<BillBaseWrapper> = .init()
    @Bindable private var deleting: DeletingManifest<BillBaseWrapper> = .init()
    @Bindable private var warning: SelectionWarningManifest = .init()
    @State private var selection: Set<BillBaseWrapper.ID> = [];
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        let filteredBills = bills.filter { $0.isExpired }.map { BillBaseWrapper($0) }
        let filteredUtilities = utilities.filter { $0.isExpired }.map { BillBaseWrapper($0) }
        
        query.apply(filteredBills + filteredUtilities)
    }
    private func deleteFromModel(_ data: BillBaseWrapper, context: ModelContext) {
        if let bill = data.data as? Bill {
            context.delete(bill)
        }
        else if let utility = data.data as? Utility {
            context.delete(utility)
        }
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
        
        ToolbarItem(placement: .secondaryAction) {
            Button(action: refresh) {
                Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
            }
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
    private func inspectSheet(_ wrapper: BillBaseWrapper) -> some View {
        if let asBill = wrapper.data as? Bill {
            ElementIE(asBill, mode: inspect.mode)
        }
        else if let asUtility = wrapper.data as? Utility {
            ElementIE(asUtility, mode: inspect.mode)
        }
        else {
            VStack {
                Text("internalError").italic()
                Button("Ok", action: {
                    inspect.value = nil
                }).buttonStyle(.borderedProminent)
            }
        }
    }
    
    @ViewBuilder
    private var regular: some View {
        if query.cached.isEmpty {
            empty
        }
        else {
            Table(query.cached, selection: $selection) {
                TableColumn("Name") { wrapper in
                    if horizontalSizeClass == .compact {
                        HStack {
                            Text(wrapper.data.name)
                            Spacer()
                            Text("Ended:", comment: "Bill ended on date")
                            if let end = wrapper.data.endDate {
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
                        Text(wrapper.data.name)
                    }
                }
                TableColumn("Kind") { wrapper in
                    Text(wrapper.data.kind.display)
                }
                TableColumn("Started On") { wrapper in
                    Text(wrapper.data.startDate.formatted(date: .abbreviated, time: .omitted))
                }
                TableColumn("Ended On") { wrapper in
                    if let end = wrapper.data.endDate {
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
                    Text(wrapper.data.amount, format: .currency(code: currencyCode))
                }
                TableColumn("Frequency") { wrapper in
                    Text(wrapper.data.period.perName)
                }
#endif
            }.contextMenu(forSelectionType: BillBaseWrapper.ID.self) { selection in
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
            .sheet(item: $inspect.value, content: inspectSheet)
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message)
            }).confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting, titleVisibility: .visible) {
                AbstractDeletingActionConfirm(deleting, delete: deleteFromModel, post: refresh)
            }.padding()
                .onAppear(perform: refresh)
                .onChange(of: query.hashValue, refresh)
                .toolbarRole(horizontalSizeClass == .compact ? .automatic : .editor)
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    NavigationStack {
        AllExpiredBillsVE()
    }
}

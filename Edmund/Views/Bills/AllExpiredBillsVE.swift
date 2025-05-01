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
    @Bindable private var warning: WarningManifest = .init()
    @State private var selection: Set<BillBaseWrapper.ID> = [];
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        let filteredBills = bills.filter { $0.isExpired }.map { BillBaseWrapper($0) }
        let filteredUtilities = utilities.filter { $0.isExpired }.map { BillBaseWrapper($0) }
        
        var combined: [BillBaseWrapper] = []
        combined.append(contentsOf: filteredBills)
        combined.append(contentsOf: filteredUtilities)
        
        query.apply(combined)
    }
    private func deleteFromModel(_ data: BillBaseWrapper, context: ModelContext) {
        if let bill = data.data as? Bill {
            context.delete(bill)
        }
        else if let utility = data.data as? Utility {
            context.delete(utility)
        }
    }
    
    private var wrappers: [BillBaseWrapper] {
        query.cached
    }
    
    @ViewBuilder
    private var empty: some View {
        VStack {
            Spacer()
            Text("There are no expired bills").italic().font(.subheadline)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var compact: some View {
        if wrappers.isEmpty {
            empty
        }
        else {
            List(wrappers, selection: $selection) { wrapper in
                HStack {
                    Text(wrapper.data.name)
                    Spacer()
                    Text("Ended On")
                    if let end = wrapper.data.endDate {
                        Text(end.formatted(date: .abbreviated, time: .omitted))
                    }
                    else {
                        Text("No Information").italic()
                    }
                }.swipeActions(edge: .trailing) {
                    SingularContextMenu(wrapper, inspect: inspect, remove: deleting, asSlide: true)
                }
            }
        }
    }
    
    @ViewBuilder
    private var regular: some View {
        if wrappers.isEmpty {
            empty
        }
        else {
            Table(wrappers, selection: $selection) {
                TableColumn("Name", value: \.data.name)
                TableColumn("Kind") { wrapper in
                    Text(wrapper.data.kind.name)
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
                TableColumn("Amount") { wrapper in
                    HStack {
                        Text(wrapper.data.amount, format: .currency(code: currencyCode))
                        Text("/")
                        Text(wrapper.data.period.perName)
                        Spacer()
                    }.frame(minWidth: 120)
                }
            }.contextMenu(forSelectionType: BillBaseWrapper.ID.self) { selection in
                ManyContextMenu(selection, data: query.cached, inspect: inspect, delete: deleting, warning: warning)
            }
            #if os(macOS)
            .frame(minWidth: 350)
            #endif
        }
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                regular
            }
        }.navigationTitle("Expired Bills")
            .toolbar(id: "expiredBillsToolbar") {
                ToolbarItem(id: "query", placement: .secondaryAction) {
                    QueryButton(provider: query)
                }
                
                ToolbarItem(id: "refresh", placement: .secondaryAction) {
                    Button(action: refresh) {
                        Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                    }
                }
                
                GeneralIEToolbarButton(on: query.cached, selection: $selection, inspect: inspect, warning: warning, role: .view, placement: .secondaryAction)
                
                GeneralIEToolbarButton(on: query.cached, selection: $selection, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
                
                GeneralDeleteToolbarButton(on: query.cached, selection: $selection, delete: deleting, warning: warning, placement: .primaryAction)
                
                #if os(iOS)
                ToolbarItem(id: "iosEdit", placement: .primaryAction) {
                    EditButton()
                }
                #endif
            }.sheet(item: $inspect.value) { wrapper in
                if let asBill = wrapper.data as? Bill {
                    BillIE(asBill, mode: inspect.mode)
                }
                else if let asUtility = wrapper.data as? Utility {
                    UtilityIE(asUtility, mode: inspect.mode)
                }
                else {
                    VStack {
                        Text("Unexpected Error").italic()
                        Button("Ok", action: {
                            inspect.value = nil
                        }).buttonStyle(.borderedProminent)
                    }
                }
            }.alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message)
            }).confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting) {
                AbstractDeletingActionConfirm(deleting, delete: deleteFromModel, post: refresh)
            }.padding().onAppear(perform: refresh).onChange(of: query.hashValue, refresh).toolbarRole(.editor)
    }
}

#Preview {
    NavigationStack {
        AllExpiredBillsVE().modelContainer(Containers.debugContainer)
    }
}

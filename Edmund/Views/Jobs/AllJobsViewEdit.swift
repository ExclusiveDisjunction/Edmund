//
//  AllJobsViewEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData
import EdmundCore

/// A view representing all jobs currently stored.
struct AllJobsViewEdit : View {
    @State private var selection = Set<TraditionalJobWrapper.ID>();
    
    @Bindable private var inspect: InspectionManifest<TraditionalJobWrapper> = .init();
    @Bindable private var deleting: DeletingManifest<TraditionalJobWrapper> = .init();
    @Bindable private var warning = WarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
#if os(iOS)
    private let openWindowPlacement: ToolbarItemPlacement = .topBarLeading
#else
    private let openWindowPlacement: ToolbarItemPlacement = .automatic
#endif
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Query private var hourly: [HourlyJob];
    @Query private var salary: [SalariedJob];
    
    @State private var cache: [TraditionalJobWrapper] = [];
    
    private func refresh() {
        self.cache = ((hourly as [any TraditionalJob]) + (salary as [any TraditionalJob]))
            .map { TraditionalJobWrapper($0) }
    }
    private func addJob(hourly: Bool) {
        if hourly {
            inspect.open(TraditionalJobWrapper(HourlyJob()), mode: .add)
        }
        else {
            inspect.open(TraditionalJobWrapper(SalariedJob()), mode: .add)
        }
    }
    private func deleteFromModel(data: TraditionalJobWrapper, context: ModelContext) {
        withAnimation {
            if let hourly = data.data as? HourlyJob {
                context.delete(hourly)
            }
            else if let salaried = data.data as? SalariedJob {
                context.delete(salaried)
            }
        }
    }
    
    @ViewBuilder
    private var compact: some View {
        List(cache, selection: $selection) { wrapper in
            HStack {
                Text(wrapper.data.position)
                Spacer()
                Text("Avg. Pay:")
                Text(wrapper.data.estimatedProfit, format: .currency(code: currencyCode))
            }.swipeActions(edge: .trailing) {
                SingularContextMenu(wrapper, inspect: inspect, remove: deleting, asSlide: true)
            }
        }.contextMenu(forSelectionType: TraditionalJobWrapper.ID.self) { selection in
            SelectionContextMenu(selection, data: cache, inspect: inspect, delete: deleting, warning: warning)
        }
    }
    
    @ViewBuilder
    private var wide: some View {
        Table(cache, selection: $selection) {
            TableColumn("Position") { wrapper in
                Text(wrapper.data.position)
            }
            TableColumn("Company") { wrapper in
                Text(wrapper.data.company)
            }
            TableColumn("Gross Pay") { wrapper in
                Text(wrapper.data.grossAmount, format: .currency(code: currencyCode))
            }
            TableColumn("Tax Rate") { wrapper in
                Text(wrapper.data.taxRate, format: .percent)
            }
            TableColumn("Estimated Pay") { wrapper in
                Text(wrapper.data.estimatedProfit, format: .currency(code: currencyCode))
            }
        }.contextMenu(forSelectionType: TraditionalJobWrapper.ID.self) { selection in
            SelectionContextMenu(selection, data: cache, inspect: inspect, delete: deleting, warning: warning)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        ToolbarItem(id: "add", placement: .primaryAction) {
            Menu {
                Button("Hourly", action: { addJob(hourly: true ) } )
                Button("Salaried", action: { addJob(hourly: false ) } )
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: cache, selection: $selection, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
            
            GeneralIEToolbarButton(on: cache, selection: $selection, inspect: inspect, warning: warning, role: .view, placement: .primaryAction)
        }
        
        #if os(iOS)
        ToolbarItem(id: "editButton", placement: .primaryAction) {
            EditButton()
        }
        #endif
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                wide
            }
        }.padding()
            .navigationTitle("Jobs")
            .onAppear(perform: refresh)
            .sheet(item: $inspect.value) { wrapper in
                if let hourly = wrapper.data as? HourlyJob {
                    ElementIE(hourly, mode: inspect.mode, postAction: refresh)
                }
                else if let salaried = wrapper.data as? SalariedJob {
                    ElementIE(salaried, mode: inspect.mode, postAction: refresh)
                }
            }.toolbar(id: "allJobsToolbar") {
                toolbar
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            }).confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting) {
                AbstractDeletingActionConfirm(deleting, delete: deleteFromModel, post: refresh)
            }
    }
}

#Preview {
    NavigationStack {
        AllJobsViewEdit()
            .modelContainer(Containers.debugContainer)
    }
}

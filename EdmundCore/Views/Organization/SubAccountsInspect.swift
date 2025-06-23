//
//  SubAccountsInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/23/25.
//

import SwiftUI
import SwiftData

/// A view used to inspect, edit, and remove the sub accounts from a specific account.
public struct SubAccountsInspect : View {
    public let children: [SubAccount];
    
    @State private var selection: Set<SubAccount.ID> = .init();
    
    @Bindable private var inspection: InspectionManifest<SubAccount> = .init();
    @Bindable private var warning: SelectionWarningManifest = .init();
    @Bindable private var deleting: DeletingManifest<SubAccount> = .init();
    
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            HStack {
                Text("Sub Accounts")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { inspection.open(.init(), mode: .add) }) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                
                Button(action: { inspection.inspectSelected(selection, mode: .inspect, on: children, warning: warning) } ) {
                    Image(systemName: "info.circle")
                }.buttonStyle(.borderless)
                
                Button(action: { inspection.inspectSelected(selection, mode: .edit, on: children, warning: warning) }) {
                    Image(systemName: "pencil")
                }.buttonStyle(.borderless)
                
                Button(action: { deleting.deleteSelected(selection, on: children, warning: warning) } ) {
                    Image(systemName: "trash")
                }.foregroundStyle(.red)
                    .buttonStyle(.borderless)
                
#if os(iOS)
                EditButton()
#endif
            }
            
            Table(children, selection: $selection) {
                TableColumn("Name", value: \.name)
            }.frame(minHeight: 200)
                .contextMenu(forSelectionType: SubAccount.ID.self) { selection in
                    SelectionContextMenu(selection, data: children, inspect: inspection, delete: deleting, warning: warning)
                }
                .sheet(item: $inspection.value) { target in
                    ElementIE(target, mode: inspection.mode)
                }
                .confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting) {
                    DeletingActionConfirm(deleting)
                }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    SubAccountsInspect(children: Account.exampleAccount.children)
}

//
//  SubAccountsInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/24/25.
//

import SwiftUI
import SwiftData
import EdmundCore

/// A view used to inspect, edit, and remove the sub accounts from a specific account.
public struct SubAccountsInspect : View {
    public let children: [SubAccount];
    
    @State private var selection: Set<SubAccount.ID> = .init();
    
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            HStack {
                Text("Sub Accounts")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {  }) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
                
                Button(action: {  } ) {
                    Image(systemName: "info.circle")
                }.buttonStyle(.borderless)
                
                Button(action: {  }) {
                    Image(systemName: "pencil")
                }.buttonStyle(.borderless)
                
                Button(action: {  } ) {
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

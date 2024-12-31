//
//  AccPair.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI;

struct NamedPairEditor : View {
    @Binding var acc: NamedPair;
    
    var body: some View {
        HStack {
            switch acc.kind {
            case .account:
                TextField("Account", text: $acc.parent)
                TextField("Sub Account", text: $acc.child)
            case .category:
                TextField("Category", text: $acc.parent)
                TextField("Sub Category", text: $acc.child)
            }
            
        }
    }
}

struct NamedPairViewer : View {
    var acc: NamedPair;
    
    var body: some View {
        Text("\(acc.parent).\(acc.child)")
    }
}

#Preview {
    let acc: NamedPair = .init("Checking", "Credit Card", kind: .account);
    
    VStack {
        NamedPairEditor(acc: Binding<NamedPair>(
            get: {
                NamedPair("", "", kind: .account)
            },
            set: { _ in
                
            }
        ))
        NamedPairEditor(acc: Binding<NamedPair>(
            get: {
                NamedPair("", "", kind: .category)
            },
            set: { _ in
                
            }
        ))
        NamedPairViewer(acc: acc)
    }
}

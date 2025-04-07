//
//  Transfer.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import SwiftUI
import SwiftData

struct Transfer: View, TransactionEditorProtocol {
    init(_ signal: TransactionEditorSignal, kind: TransferKind, categories: CategoriesContext?) {
        self.kind = kind
        self.signal = signal
        self.categories = categories
        
        self.signal.action = self.apply
    }
    
    @Environment(\.modelContext) private var modelContext;
    @State private var kind: TransferKind;
    private let categories: CategoriesContext?;
    var signal: TransactionEditorSignal;
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        false
    }
    
    @ViewBuilder
    private var oneOne: some View {
        Text("one One")
    }
    @ViewBuilder
    private var oneMany: some View {
        Text("one One")
    }
    @ViewBuilder
    private var manyOne: some View {
        Text("one One")
    }
    @ViewBuilder
    private var manyMany: some View {
        Text("one One")
    }
    
    var body: some View {
        VStack {
            Picker("Kind", selection: $kind) {
                ForEach(TransferKind.allCases, id: \.id) { kind in
                    Text(kind.name).tag(kind)
                }
            }
            
            switch self.kind {
                case .oneOne: OneOneTransfer(signal)
                case .oneMany: oneMany
                case .manyOne: manyOne
                case .manyMany: manyMany
            }
        }
    }
}

#Preview {
    let signal = TransactionEditorSignal()
    let kind = TransferKind.oneMany
    
    Transfer(signal, kind: kind, categories: nil)
}

//
//  Transfer.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import SwiftUI
import SwiftData

enum TransferKind : CaseIterable, Identifiable, Equatable, Hashable{
    case oneOne, oneMany, manyOne, manyMany
    
    var name: LocalizedStringKey {
        switch self {
            case.oneOne: return "One-to-One"
            case .oneMany: return "One-to-Many"
            case .manyOne: return "Many-to-One"
            case .manyMany: return "Many-to-Many"
        }
    }
    
    var id: Self { self }
}

struct Transfer: View, TransactionEditorProtocol {
    init(_ signal: TransactionEditorSignal, kind: TransferKind) {
        self.kind = kind
        self.signal = signal
        
        self.signal.action = self.apply
    }
    
    @Environment(\.modelContext) private var modelContext;
    @State private var kind: TransferKind;
    var signal: TransactionEditorSignal;
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        false
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
                case .oneMany: EmptyView()
                case .manyOne: EmptyView()
                case .manyMany: EmptyView()
            }
        }
    }
}

#Preview {
    let signal = TransactionEditorSignal()
    let kind = TransferKind.oneMany
    
    Transfer(signal, kind: kind)
}

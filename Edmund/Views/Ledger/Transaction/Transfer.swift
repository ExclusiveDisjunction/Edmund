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

struct Transfer: View {
    init(_ kind: TransferKind) {
        self.kind = kind
    }
    
    private let kind: TransferKind;
    
    var body: some View {
        switch self.kind {
            case .oneOne:   OneOneTransfer()
            case .oneMany:  OneManyTransfer()
            case .manyOne:  ManyOneTransfer()
            case .manyMany: ManyManyTransfer()
        }
    }
}

#Preview {
    Transfer(.oneMany)
}

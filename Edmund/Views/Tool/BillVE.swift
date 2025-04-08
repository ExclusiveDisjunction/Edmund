//
//  BillEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

@Observable
class BillManifest : Identifiable, Hashable, Equatable {
    init(_ from: Bill) {
        self.id = UUID();
        self.base = .init(from)
        self.amount = from.amount
        self.kind = from.kind
    }
    
    var id: UUID;
    var base: BillBaseManifest;
    var amount: Decimal;
    var kind: BillsKind;
    
    func apply(_ to: inout Bill) {
        base.apply(&to)
        to.amount = amount
        to.kind = kind
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(amount)
        hasher.combine(kind)
    }
    
    static func ==(lhs: BillManifest, rhs: BillManifest) -> Bool {
        lhs.base == rhs.base && lhs.amount == rhs.amount && lhs.kind == rhs.kind
    }
}

struct BillVE : View {
    var data: Bill;
    
    init(_ bill: Bill, isEdit: Bool) {
        self.data = bill
    }
    
    var body: some View {
        Text("WIP")
    }
}

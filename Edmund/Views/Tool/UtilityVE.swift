//
//  UtilityVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import Foundation
import SwiftUI

@Observable
class UtilityEntryManifest: Identifiable, Hashable, Equatable {
    init(_ from: UtilityEntry) {
        self.amount = from.amount
        self.date = from.date
        self.id = UUID()
    }
    init() {
        self.id = UUID()
        self.amount = 0
        self.date = Date.now
    }
    
    var id: UUID;
    var amount: Decimal;
    var date: Date;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
    }
    static func ==(lhs: UtilityEntryManifest, rhs: UtilityEntryManifest) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}
@Observable
class UtilityManifest : Identifiable, Hashable, Equatable {
    init(_ from: Utility) {
        self.id = UUID()
        self.base = .init(from)
        self.children = from.children.map { UtilityEntryManifest($0) }
    }
    
    var id: UUID;
    var base: BillBaseManifest;
    var children: [UtilityEntryManifest];
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(children)
    }
    static func ==(lhs: UtilityManifest, rhs: UtilityManifest) -> Bool {
        lhs.base == rhs.base && lhs.children == rhs.children
    }
    
    func apply(_ to: Utility) {
        base.apply(to)
        to.children = children.map { UtilityEntry($0.date, $0.amount) }
    }
}

struct UtilityVE : View {
    @Bindable private var bill: Utility;
    @State private var editing: UtilityManifest?;
    @State private var editHash: Int;
    @State private var showAlert: Bool = false;
    
    var isEdit: Bool {
        get { editing != nil }
    }
    
    func submit() {
        
    }
    func cancel() {
        
    }
    func toggleMode() {
        
    }
    
    @ViewBuilder
    private func edit(_ manifest: UtilityManifest) -> some View {
        Grid {
            
        }
    }
    @ViewBuilder
    private func view() -> some View {
        Grid {
            
        }
    }
    
    var body: some View {
        VStack {
            Text(bill.name).font(.title2)
            Button(action: toggleMode) {
                Image(systemName: isEdit ? "info.circle" : "pencil").resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.accent)
#if os(iOS)
                .padding(.trailing)
#endif
            
            Divider().padding([.top, .bottom])
            
            if let editing = editing {
                edit(editing)
            }
            else {
                view()
            }
            
            HStack {
                Spacer()
                
                if isEdit {
                    Button("Cancel", action: cancel).buttonStyle(.bordered)
                }
                
                Button("Ok", action: isEdit ? submit : cancel).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please fill in all fields")
        })
    }
}

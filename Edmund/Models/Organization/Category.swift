//
//  Category.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI

extension Category : DefaultableElement, NamedElement, TransactionHolder {

    public var name: String {
        get { self.internalName ?? "" }
        set { self.internalName = newValue }
    }
    public var desc : String {
        get { self.internalDesc ?? "" }
        set { self.internalDesc = newValue }
    }
    public var transactions: [LedgerEntry] {
        get {
            guard let ledger = self.ledger, let transactions = ledger as? Set<LedgerEntry> else {
                return Array()
            }
            
            return Array(transactions)
        }
        set {
            self.ledger = Set(newValue) as NSSet
        }
    }
    
    /*
     public func update(_ from: CategorySnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
     let name = from.name.trimmingCharacters(in: .whitespacesAndNewlines)
     let desc = from.desc.trimmingCharacters(in: .whitespacesAndNewlines)
     
     if name != self.name {
     guard await unique.swapId(key: Self.objId, oldId: self.name, newId: name) else {
     throw .init(value: name)
     }
     }
     
     self.name = name
     self.desc = desc
     }
     */
    
    public static func examples(cx: NSManagedObjectContext) {
        [
            "Transfers",
            "Income",
            "Adjustments",
            "Personal",
            "Groceries",
            "Health",
            "Home",
            "Car",
            "Bills"
        ].forEach { name in
            let cat = Category(context: cx);
            cat.internalName = name
        }
    }
}

/*
 extension Category : TypeTitled, EditableElement, InspectableElement {
 public static var typeDisplay : TypeTitleStrings {
 .init(
 singular: "Category",
 plural:   "Categories",
 inspect:  "Inspect Category",
 edit:     "Edit Category",
 add:      "Add Category"
 )
 }
 
 public func makeInspectView() -> some View {
 CategoryInspect(data: self)
 }
 public static func makeEditView(_ snap: CategorySnapshot) -> some View {
 CategoryEdit(snapshot: snap)
 }
 }
 */

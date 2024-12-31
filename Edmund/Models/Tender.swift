//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

@Model
public class LedgerEntry : ObservableObject, Identifiable
{
    init(memo: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category: String, sub_category: String, account: String, sub_account: String) {
        self.id = UUID()
        self.memo = memo
        self.credit = credit
        self.debit = debit
        self.t_date = date
        self.added_on = added_on;
        self.location = location
        self.category = category
        self.sub_category = sub_category
        self.account = account
        self.sub_account = sub_account
    }
    convenience init(memo: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category_pair: NamedPair, account_pair: NamedPair) {
        self.init(memo: memo, credit: credit, debit: debit, date: date, added_on: added_on, location: location, category: category_pair.parent, sub_category: category_pair.child, account: account_pair.parent, sub_account: account_pair.child)
    }
    
    public var id: UUID;
    public var memo: String;
    public var credit: Decimal;
    public var debit: Decimal;
    public var t_date: Date;
    public var added_on: Date;
    public var location: String;
    public var category: String;
    public var sub_category: String;
    public var account: String;
    public var sub_account: String;
    
    public var category_pair: NamedPair {
        NamedPair(self.category, self.sub_category, kind: .category)
    }
    public var account_pair: NamedPair {
        NamedPair(self.account, self.sub_account, kind: .account)
    }
}

public enum NamedPairKind{
    case account;
    case category;
}
public class NamedPair : Hashable {
    public static func == (lhs: NamedPair, rhs: NamedPair) -> Bool {
        return lhs.parent == rhs.parent && lhs.child == rhs.child && lhs.kind == rhs.kind;
    }
    
    init(_ parent: String = "", _ child: String = "", kind: NamedPairKind) {
        self.parent = parent;
        self.child = child;
        self.kind = kind;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(child)
        hasher.combine(kind)
    }
    
    public var parent: String;
    public var child: String;
    public var kind: NamedPairKind;
    
    public var parentEmpty: Bool {
        parent.isEmpty
    }
    public var childEmpty: Bool {
        child.isEmpty
    }
    public var isEmpty: Bool {
        parent.isEmpty || child.isEmpty
    }
}

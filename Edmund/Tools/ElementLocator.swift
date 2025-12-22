//
//  BoundPairTree.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/30/25.
//

import Foundation
import CoreData

public struct DuplicateNameError : Error, Sendable, CustomStringConvertible{
    public init(_ name: String) {
        self.name = name
    }
    
    public let name: String;
    
    public var localizedDescription: String {
        "The name \(name) is not unique"
    }
    public var description: String {
        "Duplicate name: \(name)"
    }
}

public struct ElementLocator<T> where T: NamedElement, T: Identifiable, T: NSManagedObject {
    public init<C>(data: C) throws(DuplicateNameError)
    where C: Collection, C.Element == T {
        var result: [String: T] = [:];
        for item in data {
            if let _ = result[item.name] {
                throw DuplicateNameError(item.name)
            }
            else {
                result[item.name] = item
            }
        }
        self.data = result
    }
    
    private var data: [String : T];
    
    public subscript(position: String) -> T? {
        _read {
            yield self.data[position]
        }
    }
    
    @discardableResult
    public mutating func getOrInsert(name: String, cx: NSManagedObjectContext) -> T {
        if let target = self[name] {
            return target
        }
        else {
            let new = T(context: cx);
            new.name = name
            
            self.data[name] = new;
            return new;
        }
    }
}
extension ElementLocator : Sendable where T: Sendable { }

/// A structure to help locate accounts and their envolopes.
public struct AccountLocator {
    public init(from: [Account]) {
        self.dict = [:];
        self.refresh(from: from)
    }
    public init(fetch: NSManagedObjectContext) throws {
        self.dict = [:];
        try self.refresh(fetch: fetch)
    }
    
    private var dict: [String : (Account, [ String : Envolope ])]
    
    public mutating func refresh(fetch: NSManagedObjectContext) throws {
        let results = try fetch.fetch(Account.fetchRequest());
        
        self.refresh(from: results)
    }
    public mutating func refresh(from: [Account]) {
        self.dict = [:];
        for account in from {
            let name = account.name;
            var set: [String : Envolope] = [:];
            for envolope in account.envolopes {
                set[envolope.name] = envolope;
            }
            
            self.dict[name] = (account, set)
        }
    }
    
    @discardableResult
    public func getAccount(name: String) -> Account? {
        self.dict[name]?.0
    }
    @discardableResult
    public mutating func getOrInsertAccount(name: String, cx: NSManagedObjectContext) -> Account {
        if let account = self.getAccount(name: name) {
            return account;
        }
        
        let newAccount = Account(context: cx);
        newAccount.name = name;
        self.dict[name] = (newAccount, [:]);
        
        return newAccount;
    }
    
    @discardableResult
    public func getEnvolope(name: String, accountName: String) -> Envolope? {
        self.dict[accountName]?.1[name]
    }
    @discardableResult
    public func getEnvolope(name: String, account: Account) -> Envolope? {
        self.getEnvolope(name: name, accountName: account.name)
    }
    @discardableResult
    public mutating func getOrInsertEnvolope(name: String, accountName: String, cx: NSManagedObjectContext) -> Envolope {
        let account = self.getOrInsertAccount(name: accountName, cx: cx)
        return self.getOrInsertEnvolope(name: name, account: account, cx: cx)
    }
    @discardableResult
    public mutating func getOrInsertEnvolope(name: String, account: Account, cx: NSManagedObjectContext) -> Envolope {
        if let envolope = self.getEnvolope(name: name, account: account) {
            return envolope
        }
        
        // We have to create a new envolope, and then register it to the account. Then register it.
        let newEnvolope = Envolope(context: cx);
        newEnvolope.name = name;
        newEnvolope.account = account;
        
        self.dict[account.name]?.1[name] = newEnvolope;
        
        return newEnvolope
    }
}

//
//  BalanceTools.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation
import CoreData
import Charts

/// A structure encoding credit and debit values.
public struct BalanceInformation : Sendable, Hashable, Equatable, Codable, Comparable {
    public init(credit: Decimal, debit: Decimal) {
        self.credit = credit
        self.debit = debit
    }
    public init() {
        self.credit = 0
        self.debit = 0
    }
    
    /// The amount of money that has come in.
    public var credit: Decimal;
    /// The amount of money that has left.
    public var debit: Decimal;
    
    /// The current balance.
    public var balance: Decimal {
        credit - debit
    }
    
    public static func +(lhs: BalanceInformation, rhs: BalanceInformation) -> BalanceInformation {
        .init(credit: lhs.credit + rhs.credit, debit: lhs.debit + rhs.debit)
    }
    public static func +=(lhs: inout BalanceInformation, rhs: BalanceInformation) {
        lhs.credit += rhs.credit
        lhs.debit += rhs.debit
    }
    
    public static func ==(lhs: BalanceInformation, rhs: BalanceInformation) -> Bool {
        lhs.credit == rhs.credit && lhs.debit == rhs.debit
    }
    public static func<(lhs: BalanceInformation, rhs: BalanceInformation) -> Bool {
        lhs.balance < rhs.balance
    }
}

/// A single element balance representing the balance of some `BoundPairParent`.
public struct SimpleBalance : Identifiable, Sendable, Equatable, Comparable {
    public init(_ name: String, credit: Decimal, debit: Decimal, id: UUID = UUID()) {
        self.name = name
        self.balance = .init(credit: credit, debit: debit)
        self.id = id
    }
    public init(_ name: String, balance: BalanceInformation, id: UUID = UUID()) {
        self.name = name
        self.balance = balance;
        self.id = id
    }
    
    public let id: UUID;
    /// The name of the assocated element.
    public let name: String;
    /// The money that has been credited to the element.
    public let balance: BalanceInformation;
    
    public static func ==(lhs: SimpleBalance, rhs: SimpleBalance) -> Bool {
        lhs.balance == rhs.balance
    }
    public static func <(lhs: SimpleBalance, rhs: SimpleBalance) -> Bool {
        lhs.balance < rhs.balance
    }
}

public struct DetailedBalance : Identifiable, Sendable, Equatable, Comparable {
    public init(_ name: String, credit: Decimal, debit: Decimal, children: [DetailedBalance] = [], id: UUID = UUID()) {
        self.id = id;
        self.name = name;
        self.balance = .init(credit: credit, debit: debit)
        self.children = children;
    }
    public init(_ name: String, balance: BalanceInformation, children: [DetailedBalance] = [], id: UUID = UUID()) {
        self.id = id;
        self.name = name;
        self.balance = balance
        self.children = children;
    }
    
    public let id: UUID;
    public let name: String;
    public let balance: BalanceInformation;
    public let children: [DetailedBalance];
    
    public static func ==(lhs: DetailedBalance, rhs: DetailedBalance) -> Bool {
        lhs.balance == rhs.balance
    }
    public static func <(lhs: DetailedBalance, rhs: DetailedBalance) -> Bool {
        lhs.balance < rhs.balance
    }
}

public struct BalanceResolver {
    /// Determines all transactions for a specifc month.
    /// - Throws: Any error occured while fetching the entries.
    /// - Note: This method returns entries returned from the context provided. These are thread isolated.
    /// - Returns: A list of ledger entry instances that occured during the `month` provided.
    /// - Parameters:
    ///     - month: The month & year to filter for.
    public static func transactionsFor(month: MonthYear, cx: NSManagedObjectContext, calendar: Calendar = .current) throws -> [LedgerEntry] {
        guard let startDate = month.start(calendar: calendar), let end = month.end(calendar: calendar) else {
            return []
        }
        
        let fetchDesc = LedgerEntry.fetchRequest();
        fetchDesc.predicate = NSPredicate(format: "internalDate != nil AND internalDate BETWEEN %@, %@", startDate as NSDate, end as NSDate);
        
        return try cx.fetch(fetchDesc);
    }
    public static func splitTransactionsByMonth(cx: NSManagedObjectContext, minimum: MonthYear? = nil, maximum: MonthYear? = nil) throws -> [MonthYear : [LedgerEntry]] {
        
    }
    
    /// Computes the simple balances for all categories using a background thread.
    /// This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``categoricalSpending(cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all categories.
    public static func categoricalSpending(using: NSPersistentContainer, priority: TaskPriority = .medium) async throws -> [SimpleBalance] {
        try await Task(priority: priority) {
            try Self.categoricalSpending(cx: using.newBackgroundContext())
        }.value
    }
    /// Computes the simple balances for all categories using the current thread, and the ``NSManagedObjectContext`` provided.
    ///  - Note: For a async, background processing version, use ``categoricalSpending(using:priority:)``.
    ///  - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    ///  - Parameters:
    ///     - cx: The ``NSManagedObjectContext`` to fetch information from.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all categories.
    public static func categoricalSpending(cx: NSManagedObjectContext) throws -> [SimpleBalance] {
        
    }
    /// Computes the simple balances for all categories, within the specified month, using a background thread.
    /// This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``categoricalSpending(cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all categories.
    public static func categoricalSpending(forMonth: MonthYear, using: NSPersistentContainer, priority: TaskPriority = .medium) async throws -> [SimpleBalance] {
        try await Task(priority: priority) {
            try Self.categoricalSpending(forMonth: forMonth, cx: using.newBackgroundContext())
        }.value
    }
    /// Computes the simple balances for all categories, within the specified month, using the current thread, and the ``NSManagedObjectContext`` provided.
    ///  - Note: For a async, background processing version, use ``categoricalSpending(forMonth:using:priority:)``.
    ///  - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    ///  - Parameters:
    ///     - cx: The ``NSManagedObjectContext`` to fetch information from.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all categories.
    public static func categoricalSpending(forMonth: MonthYear, cx: NSManagedObjectContext) throws -> [SimpleBalance] {
        
    }
    
    /// Computes the simple balances for all accounts using a background thread.
    /// This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``accountSpending(cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all accounts.
    public static func accountSpending(using: NSPersistentContainer) async throws -> [SimpleBalance] {
        try await Task(priority: .medium) { [using] in
            let cx = using.newBackgroundContext();
            
            return try Self.accountSpending(cx: cx);
        }.value
    }
    /// Computes the simple balances for all accounts using the current thread, and the ``NSManagedObjectContext`` provided.
    ///  - Note: For a async, background processing version, use ``accountSpending(using:)``.
    ///  - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    ///  - Parameters:
    ///     - cx: The ``NSManagedObjectContext`` to fetch information from.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all accounts.
    public static func accountSpending(cx: NSManagedObjectContext) throws -> [SimpleBalance] {
        let fetchDesc = Account.fetchRequest();
        fetchDesc.sortDescriptors = [NSSortDescriptor(keyPath: \Account.name, ascending: true)];
        fetchDesc.predicate = NSPredicate(fromMetadataQueryString: "internalEnvolopes != nil");
        
        let accounts = try cx.fetch(fetchDesc);
        
        var result: [SimpleBalance] = [];
        for account in accounts {
            let name = account.name;
            var balance = BalanceInformation();
            
            let envolopes = account.envolopes;
            for envolope in envolopes {
                let transactions = envolope.transactions;
                for transaction in transactions {
                    balance += BalanceInformation(credit: transaction.credit, debit: transaction.debit)
                }
            }
            
            result.append(
                SimpleBalance(name, balance: balance)
            )
        }
        
        return result.sorted();
    }
    /// Computes the detailed balances for all accounts using a background thread. This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``envolopeSpending(cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the `NSManagedObjectContext` will throw during a query fetch.
    ///  - Returns: A list of `DetailedBalance` instances, which stores the associated total credits & debits for all accounts & envolopes.
    public static func envolopeSpending(using: NSPersistentContainer) async throws -> [DetailedBalance] {
        try await Task(priority: .medium) {
            return try Self.envolopeSpending(cx: using.newBackgroundContext())
        }.value;
    }
    /// Computes the simple balances for all accounts using the current thread, and the `NSManagedObjectContext` provided.
    ///  - Note: For a async, background processing version, use `AccountBalanceResolver.makeDetailedBalances(using:)`.
    ///  - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    ///  - Parameters:
    ///     - cx: The `NSManagedObjectContext` to fetch information from.
    ///
    ///  - Throws: Any exception that the `NSManagedObjectContext` will throw during a query fetch.
    ///  - Returns: A list of `SimpleBalance` instances, which stores the associated total credits & debits for all accounts.
    public static func envolopeSpending(cx: NSManagedObjectContext) throws -> [DetailedBalance] {
        let fetchDesc = Account.fetchRequest();
        fetchDesc.sortDescriptors = [NSSortDescriptor(keyPath: \Account.name, ascending: true)];
        fetchDesc.predicate = NSPredicate(fromMetadataQueryString: "internalEnvolopes != nil");
        
        let accounts = try cx.fetch(fetchDesc);
        
        var result: [DetailedBalance] = [];
        for account in accounts {
            let name = account.name;
            var balance = BalanceInformation();
            let envolopes = account.envolopes;
            
            var children: [DetailedBalance] = [];
            for envolope in envolopes {
                let envolopeName = envolope.name;
                let transactions = envolope.transactions;
                
                var envolopeBalance = BalanceInformation();
                for transaction in transactions {
                    envolopeBalance += BalanceInformation(credit: transaction.credit, debit: transaction.debit);
                }
                
                balance += envolopeBalance;
                children.append(
                    DetailedBalance(envolopeName, balance: envolopeBalance)
                )
            }
            
            result.append(
                DetailedBalance(name, balance: balance, children: children.sorted())
            )
        }
        
        return result.sorted();
    }
    /// Computes the detailed balances for all accounts, durring a specific month, using a background thread. This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``BalanceResolver.envolopeSpending(forMonth:cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of `DetailedBalance` instances, which stores the associated total credits & debits for all accounts & envolopes.
    public static func envolopeSpending(forMonth: MonthYear, using: NSPersistentContainer) async throws -> [SimpleBalance] {
        try await Task(priority: .medium) {
            try Self.envolopeSpending(forMonth: forMonth, cx: using.newBackgroundContext())
        }.value
    }
    /// Computes the detailed balances for all accounts, durring a specifc month, using the current thread, and the `NSManagedObjectContext` provided.
    ///  - Note: For a async, background processing version, use `AccountBalanceResolver.envolopeSpending(forMonth:using:)`.
    ///  - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    ///  - Parameters:
    ///     - cx: The `NSManagedObjectContext` to fetch information from.
    ///
    ///  - Throws: Any exception that the `NSManagedObjectContext` will throw during a query fetch.
    ///  - Returns: A list of `SimpleBalance` instances, which stores the associated total credits & debits for all accounts.
    public static func envolopeSpending(forMonth: MonthYear, cx: NSManagedObjectContext) throws -> [SimpleBalance] {
        
    }
    
    public static func accountSpending(forMonth: MonthYear, using: NSPersistentContainer) async throws -> [SimpleBalance] {
        
    }
    public static func accountSpending(forMonth: MonthYear, cx: NSManagedObjectContext) async throws -> [SimpleBalance] {
        
    }
    
    
}

/// A collection of functions that can process transactions into different forms for usable information.
@MainActor
public struct TransactionResolver {
    public init(_ entries: [LedgerEntry]) {
        self.entries = entries;
    }
    
    private let entries: [LedgerEntry];
    
    /// Splits all transactions by their month and year.
    public consuming func splitByMonth() -> [MonthYear: [LedgerEntry]] {
        var result: [MonthYear: [LedgerEntry]] = [:];
        
        for entry in entries {
            guard let monthYear = MonthYear(date: entry.date) else {
                continue;
            }
            
            if result[monthYear] == nil {
                result[monthYear] = [];
            }
            
            result[monthYear]?.append(entry);
        }
        
        return result
    }
}

public extension [SimpleBalance] {
    /// Sorts the instances by the balances, in reverse order.
    func sortedByBalances() -> Self {
        return self.sorted(using: KeyPathComparator(\.balance, order: .reverse))
    }
}

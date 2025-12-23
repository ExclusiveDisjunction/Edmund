//
//  BalanceTools.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import Foundation
import CoreData

/// A protocol that represents any data that encodes a balance (credit and debit).
public protocol BalanceEncoder {
    var credit: Decimal { get }
    var debit: Decimal { get }
}

/// A structure encoding credit and debit values.
public struct BalanceInformation : Sendable, Hashable, Equatable, Codable, Comparable {
    public init(credit: Decimal, debit: Decimal) {
        self.credit = credit
        self.debit = debit
    }
    public init<T>(_ val: T) where T: BalanceEncoder {
        self.credit = val.credit
        self.debit = val.debit
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
    
    public static func +<T>(lhs: BalanceInformation, rhs: T) -> BalanceInformation
    where T: BalanceEncoder {
        .init(credit: lhs.credit + rhs.credit, debit: lhs.debit + rhs.debit)
    }
    public static func +=<T>(lhs: inout BalanceInformation, rhs: T)
    where T: BalanceEncoder {
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

/// A single balance associated with a name.
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
    /// The total balance of the associated element.
    public let balance: BalanceInformation;
    
    public static func ==(lhs: SimpleBalance, rhs: SimpleBalance) -> Bool {
        lhs.balance == rhs.balance
    }
    public static func <(lhs: SimpleBalance, rhs: SimpleBalance) -> Bool {
        lhs.balance < rhs.balance
    }
}

/// A single balance associated with a name and optional children.
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
    /// The name of the associated element.
    public let name: String;
    /// The total balance of the associated element.
    public let balance: BalanceInformation;
    /// The children elements to the current balance.
    public let children: [DetailedBalance];
    
    public static func ==(lhs: DetailedBalance, rhs: DetailedBalance) -> Bool {
        lhs.balance == rhs.balance
    }
    public static func <(lhs: DetailedBalance, rhs: DetailedBalance) -> Bool {
        lhs.balance < rhs.balance
    }
}

extension LedgerEntry : BalanceEncoder { }
extension BalanceInformation : BalanceEncoder { }

/// A collection of utilities to determine information about balances from various sources.
/// All methods are static, as there is no information to store within a structure for processing.
public struct BalanceResolver {
    /// Determines all transactions for a specifc month.
    /// - Throws: Any error occured while fetching the entries.
    /// - Note: This method returns entries returned from the context provided. These are thread isolated.
    /// - Returns: A list of ledger entry instances that occured during the `month` provided.
    /// - Parameters:
    ///     - month: The month & year to filter for.
    public static func transactionsFor(cx: NSManagedObjectContext, month: MonthYear, calendar: Calendar = .current) throws -> [LedgerEntry] {
        guard let startDate = month.start(calendar: calendar), let end = month.end(calendar: calendar) else {
            return []
        }
        
        let fetchDesc = LedgerEntry.fetchRequest();
        fetchDesc.predicate = NSPredicate(format: "internalDate != nil AND internalDate BETWEEN %@, %@", startDate as NSDate, end as NSDate);
        
        return try cx.fetch(fetchDesc);
    }
    
    /// Determines the total credits and debits for all transactions, grouped by month. This will create a background thread & context for processing.
    /// - Throws: Any error occured while fetching the entities.
    /// - Note: For a syncronous, thread bound version, use ``splitTransactionsByMonth(cx:minimum:maximum:calendar:)``.
    /// - Returns: The total balance for each found month for all transactions, bounded by the contstraints given.
    /// - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from.
    ///     - minimum: When provided, the minimum date the transaction must be from.
    ///     - maximum: When provided, the maximum date the transaction must be from.
    ///     - calendar: The calendar to use for date conversions.
    ///     - priority: The priority to give the background task to-be-spawned.
    public static func splitTransactionsByMonth(using: NSPersistentContainer, minimum: MonthYear? = nil, maximum: MonthYear? = nil, calendar: Calendar = .current, priority: TaskPriority = .medium) async throws -> [MonthYear : BalanceInformation] {
        try await Task(priority: priority) {
            try Self.splitTransactionsByMonth(cx: using.newBackgroundContext(), minimum: minimum, maximum: maximum, calendar: calendar)
        }.value
    }
    /// Determines the total credits and debits for all transactions, grouped by month.
    /// - Throws: Any error occured while fetching the entities.
    /// - Note: For an async, background processing version, use ``splitTransactionsByMonth(using:minimum:maximum:calendar:priority:)``.
    /// - Warning: This method runs splitting operations on the current called thread. Do not call this on the main thread, as it may block.
    /// - Returns: The total balance for each found month for all transactions, bounded by the contstraints given.
    /// - Parameters:
    ///     - cx: The ``NSManagedObjectContext`` to fetch information from.
    ///     - minimum: When provided, the minimum date the transaction must be from.
    ///     - maximum: When provided, the maximum date the transaction must be from.
    ///     - calendar: The calendar to use for date conversions.
    public static func splitTransactionsByMonth(cx: NSManagedObjectContext, minimum: MonthYear? = nil, maximum: MonthYear? = nil, calendar: Calendar = .current) throws -> [MonthYear : BalanceInformation] {
        
        let fetchDescription = LedgerEntry.fetchRequest();
        
        if let minimum = minimum, let maximum = maximum {
            guard let start = minimum.start(calendar: calendar), let end = maximum.end(calendar: calendar) else {
                throw CocoaError(.validationInvalidDate)
            }
            
            fetchDescription.predicate = NSPredicate(format: "internalDate between %@, %@", start as NSDate, end as NSDate);
        }
        else if let minimum = minimum {
            guard let start = minimum.start(calendar: calendar) else {
                throw CocoaError(.validationInvalidDate)
            }
            
            fetchDescription.predicate = NSPredicate(format: "internalDate >= %@", start as NSDate);
        }
        else if let maximum = maximum {
            guard let end = maximum.end(calendar: calendar) else {
                throw CocoaError(.validationInvalidDate)
            }
            
            fetchDescription.predicate = NSPredicate(format: "internalDate <= %@", end as NSDate);
        }
        
        let entries: [LedgerEntry] = try cx.fetch(fetchDescription);
        var result: [MonthYear : BalanceInformation] = [:];
        for entry in entries {
            guard let monthYear = MonthYear(date: entry.date, calendar: calendar) else {
                continue;
            }
            
            result[monthYear, default: BalanceInformation()] += BalanceInformation(credit: entry.credit, debit: entry.debit)
        }
        
        return result;
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
        let fetchDesc = Category.fetchRequest();
        fetchDesc.predicate = NSPredicate(fromMetadataQueryString: "ledger != nil");
        
        let categories = try cx.fetch(fetchDesc);
        
        var result: [SimpleBalance] = [];
        for category in categories {
            let name = category.name;
            var balance = BalanceInformation();
            
            let transactions = category.transactions;
            for transaction in transactions {
                balance += transaction;
            }
            
            result.append(
                SimpleBalance(name, balance: balance)
            )
        }
        
        return result.sorted();
    }
    /// Computes the simple balances for all categories, within the specified month, using a background thread.
    /// This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``categoricalSpending(cx:forMonth:calendar:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all categories.
    public static func categoricalSpending(using: NSPersistentContainer, forMonth: MonthYear, calendar: Calendar = .current, priority: TaskPriority = .medium) async throws -> [SimpleBalance] {
        try await Task(priority: priority) {
            try Self.categoricalSpending(cx: using.newBackgroundContext(), forMonth: forMonth, calendar: calendar)
        }.value
    }
    /// Computes the simple balances for all categories, within the specified month, using the current thread, and the ``NSManagedObjectContext`` provided.
    ///  - Note: For a async, background processing version, use ``categoricalSpending(using:forMonth:calendar:priority:)``.
    ///  - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    ///  - Parameters:
    ///     - cx: The ``NSManagedObjectContext`` to fetch information from.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all categories.
    public static func categoricalSpending(cx: NSManagedObjectContext, forMonth: MonthYear, calendar: Calendar = .current) throws -> [SimpleBalance] {
        // This will ahve a different approach to computation than the others.
        // The others used a top down approach (Category -> LedgerEntry), and summed up all totals.
        // However, this approach will require the ledger entries to be fetched first, and then compile all information.
        
        guard let start = forMonth.start(calendar: calendar), let end = forMonth.end(calendar: calendar) else {
            throw CocoaError(.validationInvalidDate);
        }
        
        let fetchDesc = LedgerEntry.fetchRequest();
        fetchDesc.predicate = NSPredicate(format: "internalDate between %@, %@", start as NSDate, end as NSDate);
        
        let entries = try cx.fetch(fetchDesc);
        var intermediateResult: [String : BalanceInformation] = [:];
        
        for entry in entries {
            guard let category = entry.category else {
                continue;
            }
            
            intermediateResult[category.name, default: BalanceInformation()] += entry;
        }
        
        return intermediateResult.map { (name, balance) in
            SimpleBalance(name, balance: balance)
        };
    }
    
    /// Computes the simple balances for all accounts using a background thread.
    /// This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``accountSpending(cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of ``SimpleBalance`` instances, which stores the associated total credits & debits for all accounts.
    public static func accountSpending(using: NSPersistentContainer, priority: TaskPriority = .medium) async throws -> [SimpleBalance] {
        try await Task(priority: priority) { [using] in
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
                    balance += transaction;
                }
            }
            
            result.append(
                SimpleBalance(name, balance: balance)
            )
        }
        
        return result.sorted();
    }
    /// Computes all account spending for a specific month using a background thread.
    /// - Note: For a sync, current thread version, use ``accountSpending(cx:forMonth:calendar:)``
    /// - Throws: Any execption that the ``NSManagedObjectContext`` will throw durring a query fetch.
    /// - Returns: A list of ``SimpleBalance`` instances, which store the associated total credits & debits for all accounts, within the specified month.
    /// - Parameters:
    ///     - using: The persistent store to fetch information from.
    ///     - forMonth: The month to filter for.
    ///     - calendar: The calendar to use for date conversions.
    ///     - priority: The priority to hand to the background task.
    public static func accountSpending(using: NSPersistentContainer, forMonth: MonthYear, calendar: Calendar, priority: TaskPriority = .medium) async throws -> [SimpleBalance] {
        try await Task(priority: priority) {
            try Self.accountSpending(cx: using.newBackgroundContext(), forMonth: forMonth, calendar: calendar)
        }.value
    }
    /// Computes all account spending for a specific month using the current thread.
    /// - Note: For an async, background thread version, use ``accountSpending(using:forMonth:calendar:priority:)``
    /// - Throws: Any execption that the ``NSManagedObjectContext`` will throw durring a query fetch.
    /// - Returns: A list of ``SimpleBalance`` instances, which store the associated total credits & debits for all accounts, within the specified month.
    /// - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    /// - Parameters:
    ///     - using: The persistent store to fetch information from.
    ///     - forMonth: The month to filter for.
    ///     - calendar: The calendar to use for date conversions.
    ///     - priority: The priority to hand to the background task.
    public static func accountSpending(cx: NSManagedObjectContext, forMonth: MonthYear, calendar: Calendar) throws -> [SimpleBalance] {
        guard let start = forMonth.start(calendar: calendar), let end = forMonth.end(calendar: calendar) else {
            throw CocoaError(.validationInvalidDate);
        }
        
        let fetchDesc = LedgerEntry.fetchRequest();
        fetchDesc.predicate = NSPredicate(format: "internalDate between %@, %@", start as NSDate, end as NSDate);
        
        let entries = try cx.fetch(fetchDesc);
        var intermediateResult: [String : BalanceInformation] = [:];
        
        for entry in entries {
            guard let envolope = entry.envolope, let account = envolope.account else {
                continue;
            }
            
            intermediateResult[account.name, default: BalanceInformation()] += entry;
        }
        
        return intermediateResult.map { (name, balance) in
            SimpleBalance(name, balance: balance)
        };
    }
    
    /// Computes the detailed balances for all accounts using a background thread. This will create a background context using the container provided.
    ///  - Note: For a non-async version, use ``envolopeSpending(cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the `NSManagedObjectContext` will throw during a query fetch.
    ///  - Returns: A list of `DetailedBalance` instances, which stores the associated total credits & debits for all accounts & envolopes.
    public static func envolopeSpending(using: NSPersistentContainer, prioirty: TaskPriority = .medium) async throws -> [DetailedBalance] {
        try await Task(priority: prioirty) {
            return try Self.envolopeSpending(cx: using.newBackgroundContext())
        }.value;
    }
    /// Computes the simple balances for all accounts using the current thread, and the `NSManagedObjectContext` provided.
    ///  - Note: For a async, background processing version, use ``envolopeSpending(using:prioirty:)``.
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
                    envolopeBalance += transaction;
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
    ///  - Note: For a non-async version, use ``envolopeSpending(forMonth:cx:)``.
    ///  - Parameters:
    ///     - using: The ``NSPersistentContainer`` to fetch information from. A background container will be created on the task, and then processed.
    ///
    ///  - Throws: Any exception that the ``NSManagedObjectContext`` will throw during a query fetch.
    ///  - Returns: A list of `DetailedBalance` instances, which stores the associated total credits & debits for all accounts & envolopes.
    public static func envolopeSpending(using: NSPersistentContainer, forMonth: MonthYear, calendar: Calendar, priority: TaskPriority = .medium) async throws -> [DetailedBalance] {
        try await Task(priority: priority) {
            try Self.envolopeSpending(cx: using.newBackgroundContext(), forMonth: forMonth, calendar: calendar)
        }.value
    }
    /// Computes the detailed balances for all accounts, durring a specifc month, using the current thread, and the `NSManagedObjectContext` provided.
    ///  - Note: For a async, background processing version, use ``envolopeSpending(using:forMonth:priority:)``.
    ///  - Warning: This will block the current thread. Do not use this on the main thread, as it may delay UI updates.
    ///  - Parameters:
    ///     - cx: The `NSManagedObjectContext` to fetch information from.
    ///
    ///  - Throws: Any exception that the `NSManagedObjectContext` will throw during a query fetch.
    ///  - Returns: A list of `SimpleBalance` instances, which stores the associated total credits & debits for all accounts.
    public static func envolopeSpending(cx: NSManagedObjectContext, forMonth: MonthYear, calendar: Calendar) throws -> [DetailedBalance] {
        guard let start = forMonth.start(calendar: calendar), let end = forMonth.end(calendar: calendar) else {
            throw CocoaError(.validationInvalidDate);
        }
        
        let fetchDesc = LedgerEntry.fetchRequest();
        fetchDesc.predicate = NSPredicate(format: "internalDate between %@, %@", start as NSDate, end as NSDate);
        
        let entries = try cx.fetch(fetchDesc);
        var intermediateResult: [String : [String : BalanceInformation]] = [:];
        
        for entry in entries {
            guard let envolope = entry.envolope, let account = envolope.account else {
                continue;
            }
            
            (intermediateResult[account.name, default: [:]])[envolope.name, default: BalanceInformation()] += entry;
        }
        
        return intermediateResult.map { (name, children) in
            var totalBalance = BalanceInformation();
            let childrenBalances = children.map { (envolopeName, balance) in
                totalBalance += balance;
                return DetailedBalance(envolopeName, balance: balance)
            };
            
            return DetailedBalance(name, balance: totalBalance, children: childrenBalances)
        };
    }
}

//
//  BudgetMonthCmputePipeline.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/3/25.
//

import os
import Foundation
import SwiftData

@MainActor
public struct BudgetGoalData<T> : Identifiable where T: BudgetGoal {
    public let id: UUID;
    public let over: T;
    public let balance: Decimal;
    public var freeToSpend: Decimal {
        let raw = over.monthlyGoal - balance;
        
        if raw < 0 {
            return 0
        }
        else {
            return raw
        }
    }
    public var overBy: Decimal {
        over.monthlyGoal >= balance ? 0 : balance - over.monthlyGoal
    }
}
@MainActor
public struct BudgetData {
    public let spending: [BudgetGoalData<BudgetSpendingGoal>];
    public let savings: [BudgetGoalData<BudgetSavingsGoal>];
}
public enum BudgetComputationError : Error {
    case invalidBudget(Date?, Date?)
    case swiftData(any Error)
}

@MainActor
struct BudgetComputePipeline {
    private struct PreparedData {
        let accounts: Set<Account>;
        let categories: Set<Category>;
    }
    private struct PreparedTransaction {
        let balance: BalanceInformation;
        let account: Account;
        let category: Category;
    }
    private struct PreparedTransactionData {
        let data: [PreparedTransaction];
    }
    
    public init(over: BudgetMonth, log: Logger?) {
        self.over = over
        self.log = log
    }
    
    private let log: Logger?;
    private let over: BudgetMonth;
    
    private func prepare() -> PreparedData {
        log?.debug("Preparing budget information for calculations.")
        let categories = Set<Category>(over.spendingGoals.compactMap { $0.association });
        let accounts   = Set<Account> (over.savingsGoals .compactMap { $0.association });
        
        log?.debug("Budget contains \(categories.count) categories and \(accounts.count) accounts to reduce.")
        
        return PreparedData(
            accounts: accounts,
            categories: categories
        )
    }
    
    private func makePredicate() -> Predicate<LedgerEntry>? {
        guard let start = over.start,
              let end = over.end else {
            return nil
        }
        
        return #Predicate<LedgerEntry> { entry in
            !entry.isVoided && entry.date >= start && entry.date <= end && entry.account != nil && entry.category != nil
        }
    }
    private func prepareTransactions(context: ModelContext, prep: PreparedData) throws(BudgetComputationError) -> PreparedTransactionData {
        guard let predicate = self.makePredicate() else {
            log?.error("Unable to get the budget's start or end date, as the predicate was not well formed.")
            throw .invalidBudget(over.start, over.end)
        }
        
        let rawTransactions: [LedgerEntry];
        do {
            rawTransactions = try context.fetch(FetchDescriptor(predicate: predicate))
        }
        catch let e {
            log?.error("Unable to obtain the transactions with the provided predicate.")
            throw .swiftData(e)
        }
        
        log?.debug("\(rawTransactions.count) were fetched for the budget.")
        
        let processed: [PreparedTransaction] = rawTransactions.compactMap { entry in
            guard let account = entry.account,
                  let category = entry.category,
                  prep.accounts.contains(account) || prep.categories.contains(category) else {
                return nil
            }
            
            return PreparedTransaction(
                balance: BalanceInformation(credit: entry.credit, debit: entry.debit),
                account: account,
                category: category
            )
        };
        
        log?.debug("\(processed.count) transactions were processed for the budget.")
        
        return .init(data: processed)
    }
    
    private func processData(input: PreparedTransactionData) -> BudgetData {
        var accounts: [Account: BalanceInformation] = [:];
        var categories: [Category : BalanceInformation] = [:];
        
        for entry in input.data {
            accounts[entry.account] = accounts[entry.account, default: .init()] + entry.balance;
            categories[entry.category] = categories[entry.category, default: .init()] + entry.balance;
        }
        
        // Now that the balances have been computed per-account and per-category, we can stitch it with the spending and savings goals.
        let spending: [BudgetGoalData<BudgetSpendingGoal>] = over.spendingGoals.compactMap { goal in
            guard let category = goal.association else {
                return nil
            }
            
            let balanceInfo = categories[category] ?? BalanceInformation();
            let balance = -balanceInfo.balance // Negative since we want the spending. If this is positive, that means that more money came in (yay!).
            
            return BudgetGoalData(id: UUID(), over: goal, balance: balance)
        }
        
        let savings: [BudgetGoalData<BudgetSavingsGoal>] = over.savingsGoals.compactMap { goal in
            guard let account = goal.association else {
                return nil
            }
            
            let balanceInfo = accounts[account] ?? BalanceInformation();
            let balance = balanceInfo.balance
            
            return BudgetGoalData(id: UUID(), over: goal, balance: balance)
        }
        
        log?.info("The budget contains \(spending.count) spending instances and \(savings.count) savings instances.")
        
        return BudgetData(spending: spending, savings: savings)
    }
    
    public consuming func compute(context: ModelContext) throws(BudgetComputationError) -> BudgetData {
        let prepared = self.prepare();
        let transactions = try self.prepareTransactions(context: context, prep: prepared)
        
        return self.processData(input: transactions)
    }
}

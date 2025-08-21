//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

extension EdmundModelsV1 {
    /// A record into the ledger, representing a single transaction.
    @Model
    public final class LedgerEntry : Identifiable {
        /// Creates a transactions with specified values.
        public init(name: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date, location: String, category: SubCategory, account: SubAccount) {
            self.id = UUID()
            self.name = name
            self.credit = credit
            self.debit = debit
            self.date = date
            self.addedOn = added_on;
            self.location = location
            self.category = category
            self.account = account
        }
        
        public var id: UUID = UUID()
        /// The memo of the transaction, a simple overview of the transaction
        public var name: String = "";
        /// How much money came in
        public var credit: Decimal = 0;
        /// How much money left
        public var debit: Decimal = 0;
        /// When it occured
        public var date: Date = Date.now;
        /// When it was recorded
        public var addedOn: Date = Date.now;
        /// The lcoation where it happened.
        public var location: String = "";
        public private(set) var isVoided: Bool = false
        /// The associated parent sub category
        @Relationship
        public var category: SubCategory? = nil;
        /// The associated parent sub account
        @Relationship
        public var account: SubAccount? = nil;
    }
}

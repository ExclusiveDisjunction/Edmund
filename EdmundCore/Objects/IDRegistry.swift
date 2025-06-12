//
//  IDRegistry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import Foundation
import SwiftData

public struct RegistryData {
    @MainActor
    public init(_ context: ModelContext) throws {
        self.acc =      try context.fetch(FetchDescriptor<Account>            ());
        self.subAcc =   try context.fetch(FetchDescriptor<SubAccount>         ());
        self.cat =      try context.fetch(FetchDescriptor<EdmundCore.Category>());
        self.subCat =   try context.fetch(FetchDescriptor<SubCategory>        ());
        let  bills =    try context.fetch(FetchDescriptor<Bill>               ());
        let  utility =  try context.fetch(FetchDescriptor<Utility>            ());
        let  hourly =   try context.fetch(FetchDescriptor<HourlyJob>          ());
        let  salaried = try context.fetch(FetchDescriptor<SalariedJob>        ());
        
        self.allBills = (bills as [any BillBase]) + (utility as [any BillBase]);
        self.allJobs =  (hourly as [any TraditionalJob]) + (salaried as [any TraditionalJob]);
    }
    
    let acc: [Account];
    let subAcc: [SubAccount];
    let cat: [EdmundCore.Category];
    let subCat: [SubCategory];
    let allBills: [any BillBase];
    let allJobs: [any TraditionalJob];
}

@Observable
public class IDRegistry {
    public init() {
        self.accounts = .init();
        self.subAccounts = .init();
        self.categories = .init();
        self.subCategories = .init();
        self.allBills = .init();
        self.allJobs = .init();
    }
    public init(_ data: RegistryData) {
        
    }
    
    public var accounts: Set<String>;
    public var subAccounts: Set<String>;
    public var categories: Set<String>;
    public var subCategories: Set<String>;
    public var allBills: Set<String>;
    public var allJobs: Set<String>;
}

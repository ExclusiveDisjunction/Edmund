
//
//  Untitled.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/22/25.
//

import os
import EdmundCore
import SwiftUI
import SwiftData
import Observation

public enum BudgetLoadingState {
    case loading
    case error(BudgetComputationError)
    case loaded(BudgetData)
    
    var isLoading: Bool {
        switch self {
            case .loading: true
            default: false
        }
    }
}

@Observable
class BudgetMonthInspectManifest {
    public init(over: BudgetMonth) {
        self.over = over
    }
    
    let over: BudgetMonth;
    private(set) var cache: BudgetLoadingState = .loading
    
    @MainActor
    public func refresh(context: ModelContext, logger: Logger?) {
        logger?.info("Refresh for \(self.over.date.description) was called.")
        withAnimation {
            self.cache = .loading
        }
        
        do {
            let pipeline = BudgetComputePipeline(over: over, log: logger)
            let result = try pipeline.compute(context: context)
            logger?.info("Budget month computation complete for month year \(self.over.date.description).")
            withAnimation {
                self.cache = .loaded(result)
            }
        }
        catch let e {
            withAnimation {
                self.cache = .error(e)
            }
        }
    }
}

//
//  IncomeKind.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

extension EdmundModelsV1_1 {
    public enum IncomeKind: Int, CaseIterable, Identifiable {
        case pay
        case gift
        case donation
        
        public var id: Self { self }
    }
}

public typealias IncomeKind = EdmundModelsV1_1.IncomeKind;

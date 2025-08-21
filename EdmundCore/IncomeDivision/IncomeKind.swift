//
//  IncomeKind.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

public enum IncomeKind: Int, CaseIterable, Identifiable {
    case pay
    case gift
    case donation
    
    public var id: Self { self }
}

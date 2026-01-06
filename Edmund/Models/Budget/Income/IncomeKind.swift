//
//  IncomeKind.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

public enum IncomeKind: Int16, CaseIterable, Identifiable, Codable {
    case pay = 0
    case gift = 1
    case donation = 2
    
    public var id: Self { self }
}

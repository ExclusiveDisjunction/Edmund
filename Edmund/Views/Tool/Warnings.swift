//
//  Warnings.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/1/25.
//

import SwiftUI

enum WarningKind {
    case noneSelected, editMultipleSelected
}

struct DeletingAction<T>{
    let data: [Bill];
}

//
//  ValidationFailure.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI
import EdmundCore

public extension ValidationFailure {
    var display: LocalizedStringKey {
        switch self {
            case .unique:         "The current element is not unique."
            case .empty:          "Please ensure all fields are filled in."
            case .negativeAmount: "Please ensure all amount values are positive."
            case .tooLargeAmount: "Please ensure all fields are not too large. (Ex: Percents greater than 100%)"
            case .tooSmallAmount: "Please ensure all fields are not too small."
            case .invalidInput:   "One or more fields has invalid input."
            case .internalError:
                fallthrough
            default:
                "internalError"
                
        }
    }
}

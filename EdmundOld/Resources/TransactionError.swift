//
//  TransactionError.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

class TransactionError : Error {
    init(kind: Kind, on: String, message: String? = nil) {
        self.kind = kind
        self.on = on;
        self.message = message ??  "";
    }
    
    enum Kind {
        case empty_argument
        case invalid_value
    }
    
    let kind: Kind;
    let on: String;
    let message: String;
    
    var localizedDescription: String {
        get {
            switch kind {
            case .empty_argument: on + " was empty"
            case .invalid_value: "the value stored in " + on + " was invalid because '" + message + "'"
            }
        }
    }
}

//
//  TransactionError.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

public class TransactionError : Error {
    public init(kind: Kind, on: String, message: String? = nil) {
        self.kind = kind
        self.on = on;
        self.message = message ??  "";
    }
    
    public enum Kind {
        case empty_argument
        case invalid_value
    }
    
    public let kind: Kind;
    public let on: String;
    public let message: String;
    
    public var localizedDescription: String {
        get {
            switch kind {
            case .empty_argument: on + " was empty"
            case .invalid_value: "the value stored in " + on + " was invalid because '" + message + "'"
            }
        }
    }
}

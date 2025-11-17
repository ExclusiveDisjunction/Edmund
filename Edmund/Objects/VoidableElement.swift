//
//  VoidableElement.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/21/25.
//

import Foundation

public protocol VoidableElement {
    var isVoided: Bool { get }
    
    /// Sets the void status for the current element, and possibly all elements beneath it to `new`.
    /// If `new` is false, this element and all children beneath will it be `false` as well.
    /// If `new` is true, this element ONLY will be un-voided.
    /// If the new status is different from current status, nothing will happen.
    func setVoidStatus(_ new: Bool);
}
public extension VoidableElement {
    static var voidedFilteredPredicate : Predicate<Self> {
        #Predicate<Self> {
            !$0.isVoided
        }
    }
}

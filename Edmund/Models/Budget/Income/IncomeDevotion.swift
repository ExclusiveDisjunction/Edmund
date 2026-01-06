//
//  DevotionBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation
import SwiftUI

public enum DevotionGroup : Int16, Identifiable, CaseIterable, Codable {
    case need = 0
    case want = 1
    case savings = 2
    
    public var id: Self { self }
}

extension IncomeDevotion {
    public var name: String {
        get { self.internalName ?? "" }
        set { self.internalName = newValue }
    }
    public var group: DevotionGroup {
        get { DevotionGroup(rawValue: self.internalGroup) ?? .want }
        set { self.internalGroup = newValue.rawValue}
    }
    @objc open var amount: Decimal {
        get { 0.0 }
    }
}
extension AmountDevotion {
    @objc public override var amount: Decimal {
        get { self.internalAmount as Decimal? ?? 0.0 }
        set { self.internalAmount = newValue as NSDecimalNumber }
    }
}
extension PercentDevotion {
    public var percent: Decimal {
        get { self.internalPercent as Decimal? ?? 0.0 }
        set { self.internalPercent = newValue as NSDecimalNumber }
    }
    @objc public override var amount: Decimal {
        get {
            guard let parent = self.division else {
                return 0.0;
            }
            
            return self.percent * parent.amount;
        }
    }
}
extension RemainderDevotion {
    @objc public override var amount: Decimal {
        get {
            guard let parent = self.division else {
                return 0.0;
            }
            
            return parent.remainderValue;
        }
    }
}

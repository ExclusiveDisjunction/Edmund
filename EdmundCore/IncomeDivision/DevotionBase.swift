//
//  DevotionBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation

public enum DevotionGroup : Int, Identifiable, CaseIterable {
    case need
    case want
    case savings
    
    public var asString: String {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
        }
    }
    
    public var id: Self { self }
}

public protocol DevotionBase : AnyObject, Identifiable<UUID>, SnapshotableElement, DefaultableElement, SnapshotConstructableElement  {
    var name: String { get set }
    var account: Account? { get set }
    var group: DevotionGroup { get set }
    
    func duplicate() -> Self;
}

@Observable
public class DevotionSnapshotBase : Identifiable, Hashable, Equatable, ElementSnapshot {
    public init() {
        self.id = UUID()
        self.name = ""
        self.group = .want
        self.account = nil
    }
    public init<T>(_ from: T) where T: DevotionBase {
        self.id = from.id;
        self.name = from.name
        self.group = from.group
        self.account = from.account
    }
    
    public let id: UUID;
    public var name: String;
    public var group: DevotionGroup;
    public var account: Account?;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && account != nil else {
            return .empty
        }
        
        return nil;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(group)
        hasher.combine(account)
    }
    public static func ==(lhs: DevotionSnapshotBase, rhs: DevotionSnapshotBase) -> Bool {
        lhs.name == rhs.name && lhs.group == rhs.group && lhs.account == rhs.account
    }
}

public final class DevotionSnapshot<V> : DevotionSnapshotBase where V: ValueWrapper, V.RawValue: Comparable {
    public init(value: V, min: V.RawValue, max: V.RawValue? = nil) {
        self.value = value;
        self.min = min;
        self.max = max;
        
        super.init();
    }
    public init<T>(base: T, value: V, min: V.RawValue, max: V.RawValue? = nil) where T: DevotionBase {
        self.value = value
        self.min = min
        self.max = max
        super.init(base);
    }
    
    @ObservationIgnored private let min: V.RawValue;
    @ObservationIgnored private let max: V.RawValue?;
    public var value: V;
    
    public override func validate(unique: UniqueEngine) -> ValidationFailure? {
        if let result = super.validate(unique: unique) {
            return result
        }
        
        if value.rawValue < min {
            return .negativeAmount
        }
        if let max = self.max, value.rawValue > max {
            return .tooLargeAmount
        }
        
        return nil
    }
}

//
//  RemainderDevotion.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData
import Foundation

extension RemainderDevotion : DevotionBase {
    public convenience init() {
        self.init(name: "")
    }
    public convenience init(snapshot: DevotionSnapshotBase, unique: UniqueEngine) {
        self.init(
            name: snapshot.name.trimmingCharacters(in: .whitespacesAndNewlines),
            parent: nil, account: snapshot.account,
            group: snapshot.group
        )
    }
    
    public var group: DevotionGroup {
        get {
            DevotionGroup(rawValue: _group) ?? .want
        }
        set {
            _group = newValue.rawValue
        }
    }
    
    public func duplicate() -> RemainderDevotion {
        return .init(name: self.name, parent: nil, account: self.account, group: self.group)
    }
    
    public func makeSnapshot() -> DevotionSnapshotBase {
        .init(self)
    }
    public static func makeBlankSnapshot() -> DevotionSnapshotBase {
        .init()
    }
    public func update(_ snap: DevotionSnapshotBase, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.account = snap.account
        self.group = snap.group
    }
}

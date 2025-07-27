//
//  RemainderDevotion.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1 {
    @Model
    public final class RemainderDevotion : DevotionBase {
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
        public init(name: String, parent: IncomeDivision? = nil, account: SubAccount? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
            self.id = id
            self.parent = parent;
            self.name = name;
            self.account = account
            self._group = group.rawValue
        }
        
        public var id: UUID;
        public var name: String
        private var _group: DevotionGroup.RawValue
        public var group: DevotionGroup {
            get {
                DevotionGroup(rawValue: _group) ?? .want
            }
            set {
                _group = newValue.rawValue
            }
        }
        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: SubAccount?;
        
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
}

public typealias RemainderDevotion = EdmundModelsV1.RemainderDevotion

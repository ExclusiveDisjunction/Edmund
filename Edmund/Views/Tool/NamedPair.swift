//
//  NamedPair.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI;

struct NamedPair: Hashable, Identifiable {
    init(_ name: String = "", _ sub_name: String = "", id: UUID = UUID()) {
        self.name = name;
        self.sub_name = sub_name;
        self.id = id;
    }
    
    static func ==(lhs: NamedPair, rhs: NamedPair) -> Bool {
        return lhs.name == rhs.name && lhs.sub_name == rhs.sub_name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(sub_name)
    }
    
    var isEmpty: Bool {
        name.isEmpty || sub_name.isEmpty
    }
    
    @State var name: String;
    @State var sub_name: String;
    @State var id: UUID;
}

struct NamedPairViewer : View {
    @State var pair: NamedPair;
    
    var body: some View {
        Text("\(pair.name), \(pair.sub_name)")
    }
}
struct NamedPairEditor : View {
    @Binding var pair: NamedPair;
    @State var parent_name: String = "Parent";
    @State var child_name: String = "Child";
    
    var body: some View {
        HStack {
            TextField(parent_name, text: $pair.name)
            TextField(child_name, text: $pair.sub_name)
        }
    }
}

extension [SubAccount] {
    func to_named_pair() -> [NamedPair] {
        self.reduce(into: []) { $0.append(.init($1.parent.name, $1.name, id: $1.id)) }
    }
}
extension [SubCategory] {
    func to_named_pair() -> [NamedPair] {
        self.reduce(into: []) { $0.append(.init($1.parent.name, $1.name, id: $1.id)) }
    }
}

#Preview {
    var named_pair: NamedPair = .init("Father", "Son");
    let pair_bind: Binding<NamedPair> = .init(
        get: {
            named_pair
        },
        set: {
            named_pair = $0
        }
    )
    
    VStack {
        NamedPairViewer(pair: named_pair)
        NamedPairEditor(pair: pair_bind)
    }.padding()
}

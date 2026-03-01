//
//  ExpandableList.swift
//  Edmund
//
//  Created by Hollan Sellars on 2/23/26.
//

import SwiftUI

public struct ExpandableList<C, Id, Header, Content> where C: RandomAccessCollection {
    private let data: C;
    private let idKeyPath: KeyPath<C.Element, Id>
    private let header: (C.Element) -> Header;
    private let content: (C.Element) -> Content;
}

extension ExpandableList : View where C: RandomAccessCollection, Id: Hashable, Header: View, Content: View {
    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 6) {
                ForEach(data, id: self.idKeyPath) { item in
                    ExpandableView {
                        header(item)
                    } content: {
                        content(item)
                    }.contentShape(Rectangle())
                        .padding([.leading, .trailing], 12)
                        .padding(.top, 3)
                }
            }
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 14, height: 14))
                    .fill(.background.secondary)
            )
        }.padding()
            
    }
}

extension ExpandableList where C: RandomAccessCollection, C.Element: Identifiable, C.Element.ID == Id, Header: View, Content: View {
    public init(_ data: C, @ViewBuilder header: @escaping (C.Element) -> Header, @ViewBuilder content: @escaping (C.Element) -> Content) {
        self.data = data;
        self.header = header;
        self.content = content;
        self.idKeyPath = \.id;
    }
}
extension ExpandableList where C: RandomAccessCollection, Id: Hashable, Header: View, Content: View {
    public init(_ data: C, id: KeyPath<C.Element, Id>, @ViewBuilder header: @escaping (C.Element) -> Header, @ViewBuilder content: @escaping (C.Element) -> Content) {
        self.data = data;
        self.header = header;
        self.content = content;
        self.idKeyPath = id;
    }
}

#Preview {
    ExpandableList(1...100, id: \.self) { num in
        Text(num, format: .number)
    } content: { num in
        Text("The number is \(num).")
    }
}

//
//  AltRowView.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/4/25.
//

import SwiftUI

struct AltRowWrapper<T> : Identifiable {
    init(row: Int, data: T) {
        self.data = data
        self.id = row
    }
    
    let data: T;
    let id: Int;
}
extension AltRowWrapper : Sendable where T: Sendable {

}

struct AltRowView<T, Content> : View where Content: View {
    init<C>(data: C, @ViewBuilder content: @escaping (T, Int) -> Content) where C: RandomAccessCollection, C.Element == T {
        self.content = content
        self.data = data.enumerated().map { .init(row: $0, data: $1) }
    }
    
    let data: [AltRowWrapper<T>]
    let content: (T, Int) -> Content;
    
    var body: some View {
        ForEach(data, id: \.id) { item in
            GridRow {
                ZStack {
                    if item.id % 2 == 0 {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.background)
                    }
                    else {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.background.tertiary)
                    }
                    
                    
                    HStack {
                        content(item.data, item.id)
                    }
                    //.padding([.leading, .trailing], 1)
                    //.padding([.top, .bottom], 0.25)
                }
            }
        }
    }
}

#Preview {
    let content: [String] = (1..<10).map { "Item \($0)" }
    
    Grid {
        GridRow {
            Text("Index")
                .bold()
            Text("Content")
                .bold()
        }
        
        Divider()
        
        AltRowView(data: content) { item, row in
            Text(row, format: .number)
            
            Text(item)
        }
    }.padding()
}

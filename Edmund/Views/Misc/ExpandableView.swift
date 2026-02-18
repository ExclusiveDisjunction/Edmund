//
//  ExpandableView.swift
//  Edmund
//
//  Created by Hollan Sellars on 2/18/26.
//

import SwiftUI

public struct ExpandableView<Header, Content> : View where Header: View, Content: View {
    public init(@ViewBuilder header: @escaping () -> Header, @ViewBuilder content: @escaping () -> Content) {
        self.headerBuilder = header;
        self.contentBuilder = content;
    }
    
    private let headerBuilder: () -> Header;
    private let contentBuilder: () -> Content;
    @State private var isExpanded = false;
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBuilder()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            
            if isExpanded {
                contentBuilder()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.secondary)
                    //.clipped()
                    //.frame(height: isExpanded ? nil : 0)
                    .opacity(isExpanded ? 1 : 0)
                    .transition(.push(from: .top))
                    .animation(.easeInOut(duration: 0.25), value: isExpanded)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
extension ExpandableView where Header == HStack<TupleView<(Text, Spacer)>> {
    public init(header: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.init(header: {
            HStack {
                Text(header)
                Spacer()
            }
        }, content: content)
    }
}
extension ExpandableView where Header == Label<Text, Image> {
    public init(header: LocalizedStringKey, systemImage: String, @ViewBuilder content: @escaping () -> Content) {
        self.init(header: { Label(header, systemImage: systemImage) }, content: content)
    }
}
extension ExpandableView {
    public init<InnerContent, Charms>(@ViewBuilder header: @escaping () -> Header, content: @escaping () -> InnerContent, @ViewBuilder charms: @escaping () -> Charms)
    where InnerContent: View, Charms: View,
    Content == VStack<TupleView<(InnerContent, Divider, Charms)>> {
        self.init(
            header: header,
            content: {
                VStack {
                    content()
                    Divider()
                    charms()
                }
            }
        )
    }
}
extension ExpandableView where Header == HStack<TupleView<(Text, Spacer)>> {
    public init<InnerContent, Charms>(header: LocalizedStringKey, @ViewBuilder content: @escaping () -> InnerContent, @ViewBuilder charms: @escaping () -> Charms)
    where InnerContent: View, Charms: View,
    Content == VStack<TupleView<(InnerContent, Divider, Charms)>> {
        self.init(header: {
            HStack {
                Text(header)
                Spacer()
            }
        }, content: content, charms: charms)
    }
}
extension ExpandableView where Header == Label<Text, Image> {
    public init<InnerContent, Charms>(header: LocalizedStringKey, systemImage: String, @ViewBuilder content: @escaping () -> InnerContent, @ViewBuilder charms: @escaping () -> Charms)
    where InnerContent: View, Charms: View,
    Content == VStack<TupleView<(InnerContent, Divider, Charms)>> {
        self.init(header: { Label(header, systemImage: systemImage) }, content: content, charms: charms)
    }
}

#Preview {
    let values: [(LocalizedStringKey, Int)] = [
        ("One", 1),
        ("Two", 2),
        ("Three", 3)
    ]
    
    List(values, id: \.1) { (name, num) in
        ExpandableView(header: name) {
            Text("The number is \(num)")
        }
    }
}

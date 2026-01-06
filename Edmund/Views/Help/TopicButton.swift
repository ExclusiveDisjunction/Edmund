//
//  TopicButton.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI

public enum TopicButtonStyle {
    case compact
    case textOnly
    case label
}

public protocol HelpPresenterView : View {
    init(_ key: HelpResourceID);
}

public struct TopicButtonBase<P> : View where P: HelpPresenterView {
    public init(_ key: HelpResourceID) {
        self.key = key
    }
    public init(_ key: String) {
        self.init(HelpResourceID(rawValue: key))
    }
    public init(_ key: [String]) {
        self.init(HelpResourceID(parts: key))
    }
    
    private let key: HelpResourceID;
    @State private var showSheet: Bool = false;
    private var style: TopicButtonStyle = .label
    
    func topicButtonStyle(_ new: TopicButtonStyle) -> some View {
        var result = self
        result.style = new
        return result
    }
    
    public var body: some View {
        Button {
            showSheet = true
        } label: {
            switch style {
                case .compact: Image(systemName: "questionmark.circle")
                case .textOnly: Text("Help")
                case .label: Label("Help", systemImage: "questionmark.circle")
            }
        }.sheet(isPresented: $showSheet) {
            P(self.key)
        }
    }
}

public typealias TopicButton = TopicButtonBase<TopicPresenter>;
public typealias TopicGroupButton = TopicButtonBase<TopicGroupPresenter>;

public struct TopicBaseToolbarButton<P> : CustomizableToolbarContent where P: HelpPresenterView {
    public init(_ key: HelpResourceID, placement: ToolbarItemPlacement = .automatic) {
        self.key = key
        self.placement = placement
    }
    public init(_ key: String, placement: ToolbarItemPlacement = .automatic) {
        self.init(HelpResourceID(rawValue: key), placement: placement)
    }
    public init(_ key: [String], placement: ToolbarItemPlacement = .automatic) {
        self.init(HelpResourceID(parts: key), placement: placement)
    }
    
    private let key: HelpResourceID;
    private let placement: ToolbarItemPlacement;
    
    @ToolbarContentBuilder
    public var body: some CustomizableToolbarContent {
        ToolbarItem(id: "helpTopic", placement: placement) {
            TopicButtonBase<P>(key)
                .topicButtonStyle(.label)
        }
    }
}

public typealias TopicToolbarButton = TopicBaseToolbarButton<TopicPresenter>;
public typealias TopicGroupToolbarButton = TopicBaseToolbarButton<TopicGroupPresenter>;

#Preview {
    TopicButton("Help/Welcome.md")
        .padding()
}

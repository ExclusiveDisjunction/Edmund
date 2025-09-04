//
//  TopicButton.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import SwiftUI

enum TopicButtonStyle {
    case compact
    case textOnly
    case label
}

public protocol HelpPresenterView : View {
    init(_ key: HelpResourceID);
}

struct TopicButtonBase<P> : View where P: HelpPresenterView {
    init(_ key: HelpResourceID) {
        self.key = key
    }
    init(_ key: String) {
        self.init(HelpResourceID(rawValue: key))
    }
    init(_ key: [String]) {
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
    
    var body: some View {
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

typealias TopicButton = TopicButtonBase<TopicPresenter>;
typealias TopicGroupButton = TopicButtonBase<TopicGroupPresenter>;

struct TopicBaseToolbarButton<P> : CustomizableToolbarContent where P: HelpPresenterView {
    init(_ key: HelpResourceID, placement: ToolbarItemPlacement = .automatic) {
        self.key = key
        self.placement = placement
    }
    init(_ key: String, placement: ToolbarItemPlacement = .automatic) {
        self.init(HelpResourceID(rawValue: key), placement: placement)
    }
    init(_ key: [String], placement: ToolbarItemPlacement = .automatic) {
        self.init(HelpResourceID(parts: key), placement: placement)
    }
    
    private let key: HelpResourceID;
    private let placement: ToolbarItemPlacement;
    
    @ToolbarContentBuilder
    var body: some CustomizableToolbarContent {
        ToolbarItem(id: "helpTopic", placement: placement) {
            TopicButtonBase<P>(key)
                .topicButtonStyle(.label)
        }
    }
}

typealias TopicToolbarButton = TopicBaseToolbarButton<TopicPresenter>;
@available(*, deprecated, message: "On macOS, this does not display properly and should not be used.")
typealias TopicGroupToolbarButton = TopicBaseToolbarButton<TopicGroupPresenter>;

#Preview {
    TopicButton("Help/Welcome.md")
        .padding()
}

//
//  ElementInspectEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;
import EdmundCore

/// A high level view that allows for switching between editing and inspecting
public struct ElementIE<T> : View where T: InspectableElement, T: EditableElement, T: PersistentModel, T: TypeTitled, T.ID: Sendable {
    /// Opens the editor with a specific mode.
    /// - Parameters:
    ///     - data: The data being passed for inspection/editing
    ///     - mode: The mode to open by default. The user can change the mode, unless the action is `add`. In this case, the user will be locked to editing mode only.
    ///     - postAction: An action to run after the editor closes, regardless of success or not.
    public init(_ data: T, mode: InspectionMode, postAction: (() -> Void)? = nil) {
        self.data = data
        self.startMode = mode
        self.postAction = postAction
    }
    
    private let data: T;
    private let startMode: InspectionMode;
    private let postAction: (() -> Void)?

    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        ElementIEBase(data, mode: startMode) { $mode in
            InspectEditTitle<T>(mode: mode)
            
            Button {
                withAnimation {
                    mode = mode.toggled()
                }
            } label: {
                Image(systemName: mode == .add || mode == .edit ? "info.circle" : "pencil")
            }.disabled(mode == .add)
        } footer: {
            DefaultElementIEFooter()
        } inspect: { item in
            item.makeInspectView()
        } edit: { snapshot in
            T.makeEditView(snapshot)
        }.onDisappear {
            if let postAction = postAction {
                postAction()
            }
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        ElementIE(Account.exampleAccount, mode: .inspect)
    }
}

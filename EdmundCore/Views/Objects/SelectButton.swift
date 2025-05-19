//
//  SelectButton.swift
//  Edmund
//
//  Created by Hollan on 5/19/25.
//

import SwiftUI

struct SelectButton : View {
    @Binding var editMode: EditMode;
    
    private var isEdit : Bool {
        editMode.isEditing
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                editMode = isEdit ? .inactive : .active
            }
        }) {
            Text(isEdit ? "Done" : "Select")
        }
    }
}

private struct SelectButtonPreview : View {
    @State private var editMode: EditMode = .inactive;
    
    var body: some View {
        NavigationStack {
            List(0..<5) { item in
                Text("Item \(item)")
            }.environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SelectButton(editMode: $editMode)
                }
            }
        }
    }
}

#Preview {
    SelectButtonPreview()
}

//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct ElementPicker<T> : View where T: Identifiable & NamedElement & PersistentModel {
    public init(_ target: Binding<T?>, onNil: LocalizedStringKey = "(Pick One)") {
        self._target = target
        self.onNil = onNil;
        self._id = .init(initialValue: target.wrappedValue?.id)
    }
    
    @Query private var choices: [T];
    
    @Binding private var target: T?;
    @State private var id: T.ID?;
    private let onNil: LocalizedStringKey;
    
    public var body: some View {
        Picker("", selection: $id) {
            Text(onNil)
                .italic()
                .tag(nil as T.ID?)
            
            ForEach(choices) { choice in
                Text(choice.name)
                    .tag(choice.id)
            }
        }.labelsHidden()
            .onChange(of: id) { _, newId in
                guard let id = newId else {
                    self.target = nil;
                    return;
                }
                
                self.target = choices.first(where: { $0.id == id } )
            }
    }
}

#Preview {
    var pair: Account? = Account.exampleAccount;
    let bind = Binding<Account?>(
        get: {
            pair
        },
        set: {
            pair = $0
        }
    );
    
    DebugContainerView {
        ElementPicker(bind)
            .padding()
    }
}

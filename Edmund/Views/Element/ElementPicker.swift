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
    public init<V>(_ target: Binding<T?>,
                   withPredicate filter: Predicate<T>,
                   sortOn: KeyPath<T, V>,
                   sortOrder: SortOrder = .forward,
                   onNil: LocalizedStringKey = "(Pick One)")
            where V: Comparable
    {
        self._target = target
        self.onNil = onNil;
        self._id = .init(initialValue: target.wrappedValue?.id)
        self._choices = Query(filter: filter, sort: sortOn, order: sortOrder)
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

public struct EnumPicker<T> : View where T: CaseIterable & Identifiable & Displayable, T.AllCases: RandomAccessCollection, T.ID == T {
    @Binding public var value: T;
    
    public var body: some View {
        Picker("", selection: $value) {
            ForEach(T.allCases) { element in
                Text(element.display).tag(element)
            }
        }.labelsHidden()
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

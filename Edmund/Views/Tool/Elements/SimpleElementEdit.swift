//
//  SimpleElementEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData;
import SwiftUI;

final class SimpleElementSnapshot<T> : ElementSnapshot where T: EditableElement {
    typealias Host = T;
    
    init(_ from: T) {
        self.name = from.name;
    }
    
    var name: String;
    
    func validate() -> Bool {
        !name.isEmpty;
    }
    func apply(_ to: T, context: ModelContext) {
        to.name = name;
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name);
    }
    static func == (lhs: SimpleElementSnapshot<T>, rhs: SimpleElementSnapshot<T>) -> Bool {
        lhs.name == rhs.name
    }
}
struct SimpleElementEdit<T> : ElementEditView where T: EditableElement, T.Snapshot == SimpleElementSnapshot<T> {
    typealias For = T;
    
    @Bindable private var snapshot: T.Snapshot;
    init(_ snapshot: T.Snapshot){
        self.snapshot = snapshot;
    }
     
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 80;
    let maxWidth: CGFloat = 90;
#endif
    
    var body: some View {
        HStack {
            Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            TextField("Name", text: $snapshot.name).labelsHidden()
            
            Spacer()
        }
    }
}

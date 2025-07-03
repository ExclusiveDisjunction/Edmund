//
//  ElementIEBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI
import EdmundCore

public struct GenericAction<Result> {
    public init(_ data: (() -> Result)?) {
        self.data = data
    }
    
    private var data: (() -> Result)?;
    
    @discardableResult
    public func callAsFunction() -> Result? {
        if let data = data {
            return data()
        }
        else {
            return nil
        }
    }
}

public struct SubmitActionKey : EnvironmentKey {
    public typealias Value = GenericAction<Void>
    
    public static var defaultValue: GenericAction<Void> {
        .init(nil)
    }
}
public struct CancelActionKey : EnvironmentKey {
    public typealias Value = GenericAction<Void>
    
    public static var defaultValue: GenericAction<Void> {
        .init(nil)
    }
}
public struct ElementIsEditKey: EnvironmentKey {
    public typealias Value = Bool
    public static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    var elementSubmit: GenericAction<Void> {
        get { self[SubmitActionKey.self] }
        set { self[SubmitActionKey.self] = newValue }
    }
    
    var elementCancel: GenericAction<Void> {
        get { self[CancelActionKey.self] }
        set { self[CancelActionKey.self] = newValue }
    }
    
    var elementIsEdit: Bool {
        get { self[ElementIsEditKey.self] }
        set { self[ElementIsEditKey.self] = newValue }
    }
}

@Observable
public class ElementIEManifest<T> where T: SnapshotableElement {
    init(_ data: T, isEdit: Bool) {
        self.data = data
        
        if isEdit {
            let snap = data.makeSnapshot()
            self.snapshot = snap
            self.editHash = snap.hashValue
        }
        else {
            self.snapshot = nil
            self.editHash = 0
        }
    }
    
    public let data: T;
    public var snapshot: T.Snapshot?;
    public var editHash: Int;
    
    public var isEdit: Bool {
        get {
            snapshot != nil
        }
        set {
            guard newValue != isEdit else { return }
            
            if newValue { //Was not editing, now is
                
            }
            else { // Was editing, now is not. Must check for unsaved changes and warn otherwise.
                
            }
        }
    }
    
    private var unsavedChanges: Bool {
        isEdit && (snapshot?.hashValue ?? Int()) != editHash
    }
}

public struct DefaultElementIEFooter : View {
    @Environment(\.elementCancel) private var elementCancel;
    @Environment(\.elementSubmit) private var elementSubmit;
    @Environment(\.elementIsEdit) private var isEdit;
    
    public var body: some View {
        HStack {
            Spacer()
            
            if isEdit {
                Button("Cancel", action: { elementCancel() } )
                    .buttonStyle(.bordered)
            }
            
            Button(isEdit ? "Save" : "Ok", action: { elementSubmit() })
                .buttonStyle(.borderedProminent)
        }
    }
}

public struct ElementIEBase<T, Header, Footer, Inspect, Edit> : View where T: SnapshotableElement, Header: View, Footer: View, Inspect: View, Edit: View {
    
    public init(_ data: T, isEditing: Bool,
                @ViewBuilder header:  @escaping (Binding<Bool>) -> Header,
                @ViewBuilder footer:  @escaping () -> Footer,
                @ViewBuilder inspect: @escaping (T) -> Inspect,
                @ViewBuilder edit:    @escaping (T.Snapshot) -> Edit) {
        self.header = header
        self.footer = footer
        self.inspect = inspect
        self.edit = edit
        
        self.manifest = .init(data, isEdit: isEditing)
    }
    
    private let header: (Binding<Bool>) -> Header;
    private let footer: () -> Footer;
    private let inspect: (T) -> Inspect;
    private let edit: (T.Snapshot) -> Edit;
    private var _onEditChanged: ((Bool) -> Void)?;
    private var _postAction: (() -> Void)?;
    
    public func onEditChanged(_ perform: @escaping (Bool) -> Void) -> some View {
        var result = self
        result._onEditChanged = perform
        
        return result
    }
    public func postAction(_ perform: @escaping () -> Void) -> some View {
        var result = self
        result._postAction = perform
        
        return result
    }
    
    private func submit() {
        print("submit called")
    }
    private func cancel() {
        print("cancel called")
    }

    @State private var warningConfirm: Bool = false;
    
    @Bindable private var manifest: ElementIEManifest<T>;
    @Bindable private var uniqueError: StringWarningManifest = .init()
    @Bindable private var validationError: ValidationWarningManifest = .init()
    
    public var body: some View {
        VStack {
            self.header($manifest.isEdit)
            
            if let editing = manifest.snapshot {
                self.edit(editing)
            }
            else {
                self.inspect(manifest.data)
            }
            
            self.footer()
                .environment(\.elementSubmit, .init(submit))
                .environment(\.elementCancel, .init(cancel))
                .environment(\.elementIsEdit, .init(manifest.isEdit))
        }
    }
}
public extension ElementIEBase where Footer == DefaultElementIEFooter {
    init(_ data: T, isEditing: Bool,
                @ViewBuilder header:  @escaping (Binding<Bool>) -> Header,
                @ViewBuilder inspect: @escaping (T) -> Inspect,
                @ViewBuilder edit:    @escaping (T.Snapshot) -> Edit) {
        self.init(
            data,
            isEditing: isEditing,
            header: header,
            footer: DefaultElementIEFooter.init,
            inspect: inspect,
            edit: edit
        )
    }
}

#Preview {
    
}

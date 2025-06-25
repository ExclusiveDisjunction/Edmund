//
//  Select.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

public struct SelectionValue<T> : Identifiable {
    public init(_ data: [T], id: UUID = UUID()) {
        self.data = data
        self.id = id
    }
    
    public var data: [T];
    public var id: UUID;
}

/// An observable class that provides selection implementation values.
@Observable
public class SelectionManifest<T> {
    public init() {
        self.data = nil;
    }
    
    public var data: SelectionValue<T>?;
    public var isActive: Bool {
        self.data != nil
    }
    
    public func reset() {
        self.data = nil
    }
}

public struct SelectionSheet<T, Title, Columns> : View where T: Identifiable, Columns: TableColumnContent, Columns.TableRowValue == T, Title: View {
    public init(_ source: [T], selection: SelectionManifest<T>, @ViewBuilder title: @escaping () -> Title, @TableColumnBuilder<T, Never> cols: @escaping () -> Columns) {
        self.source = source
        self.manifest = selection
        self.title = title
        self.builder = cols
    }
    
    public let source: [T];
    @Bindable private var manifest: SelectionManifest<T>;
    @State private var selected = Set<T.ID>();
    @State private var showWarning = false;
    private let builder: () -> Columns;
    private let title: () -> Title;
    
    @Environment(\.dismiss) private var dismiss;
    
    private func submit() {
        let targets = source.filter { selected.contains( $0.id ) };
        if targets.isEmpty {
            showWarning = true
        }
        else {
            dismiss()
            manifest.data = .init(targets);
        }
    }
    
    public var body: some View {
        VStack {
            HStack {
                title()
                Spacer()
            }
            
            Table(source, selection: $selected, columns: builder)
#if os(macOS)
                .frame(minHeight: 250)
#endif
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Cancel", action: {
                    dismiss()
                }).buttonStyle(.bordered)
                Button("Ok", action: submit).buttonStyle(.borderedProminent)
            }
        }.padding()
            .alert("Warning", isPresented: $showWarning, actions: {
                Button("Ok", action: {
                    showWarning = false
                })
            }, message: {
                Text("noItems")
            })
    }
}

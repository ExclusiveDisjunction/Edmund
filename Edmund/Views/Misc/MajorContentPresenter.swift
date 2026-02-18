//
//  MajorContentPresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 2/18/26.
//

import SwiftUI

public struct MajorContentPresenter<C, TableColumns, ListHeader, ListContent, ContextMenu> : View
where C: RandomAccessCollection,
      C.Element: Identifiable,
      TableColumns: TableColumnContent,
      TableColumns.TableRowValue == C.Element,
      ListHeader: View,
      ListContent: View,
      ContextMenu: View {
    
    public init(
        context: SelectionContext<C>,
        @TableColumnBuilder<C.Element, Never> cols: @escaping () -> TableColumns,
        @ViewBuilder listHeader: @escaping (C.Element) -> ListHeader,
        @ViewBuilder listContent: @escaping (C.Element) -> ListContent,
        @ViewBuilder contextMenu: @escaping (Set<C.Element.ID>) -> ContextMenu
    ) {
        self.source = context;
        self.cols = cols;
        self.listHeader = listHeader;
        self.listContent = listContent;
        self.contextMenu = contextMenu;
    }
    
    private let source: SelectionContext<C>;
    private let cols: () -> TableColumns;
    private let listHeader: (C.Element) -> ListHeader;
    private let listContent: (C.Element) -> ListContent;
    private let contextMenu: (Set<C.Element.ID>) -> ContextMenu;
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    #endif
    
    @ViewBuilder
    public var list: some View {
        List(context: source) { source in
            ExpandableView {
                listHeader(source)
            } content: {
                listContent(source)
            }
        }
        .contextMenu(forSelectionType: C.Element.ID.self, menu: contextMenu)
    }
    @ViewBuilder
    public var table: some View {
        Table(context: source, columns: cols)
            .contextMenu(forSelectionType: C.Element.ID.self, menu: contextMenu)
    }
    
    public var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            list
        }
        else {
            table
        }
        #endif
        
        table
    }
}

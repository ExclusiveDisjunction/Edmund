//
//  HelpResourcePresenter.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/13/25.
//

import SwiftUI

public struct HelpResourcePresenter<T, E, ErrorView, ContentView> : View where T: HelpResourceCore, E: Error & Sendable, ErrorView: View, ContentView: View {
    init(_ key: HelpResourceID, refresh: @escaping (HelpEngine, ResourceLoadHandle<T, E>) async -> Void, @ViewBuilder error: @escaping (E) -> ErrorView, @ViewBuilder content: @escaping (T) -> ContentView) {
        self.data = .init(id: key)
        
        self.refresh = refresh
        self.error = error
        self.content = content
    }
    
    @Environment(\.helpEngine) private var helpEngine;
    @Environment(\.dismiss) private var dismiss;
    
    private let refresh: (HelpEngine, ResourceLoadHandle<T, E>) async -> Void;
    private let error: (E) -> ErrorView;
    private let content: (T) -> ContentView;
    
    @Bindable private var data: ResourceLoadHandle<T, E>;
    @State private var task: Task<Void, Never>? = nil;
    
    private func performRefresh() {
        if let oldTask = task {
            oldTask.cancel()
        }
        
        let engine = helpEngine;
        let handle = data;
        
        task = Task {
            await refresh(engine, handle)
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        Spacer()
        
        Text("Loading")
        ProgressView()
            .progressViewStyle(.linear)
        
        Button(action: performRefresh) {
            Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
        }
        
        Spacer()
    }
    
    public var body: some View {
        switch data.status {
            case .loading:
                statusView
                    .onAppear {
                        performRefresh()
                    }
            case .error(let e):
                Spacer()
                
                error(e)
                Button("Refresh", action: performRefresh)
                
                Spacer()
            case .loaded(let v):
                VStack {
                    content(v)
                    HStack {
                        Spacer()
                        Button("Ok") {
                            dismiss()
                        }.buttonStyle(.borderedProminent)
                    }
                }
        }
    }
}

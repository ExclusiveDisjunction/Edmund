//
//  LoadableView.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/26/25.
//

import SwiftUI

struct LoadableView<T, Body> : View where Body: View, T: Sendable {
    init(_ data: Binding<T?>, process: @Sendable @escaping () async -> T, @ViewBuilder onLoad: @escaping (T) -> Body) {
        self._data = data;
        self.content = onLoad;
        self.task = process;
    }
    
    @Binding private var data: T?;
    private var content: (T) -> Body;
    private var task: () async throws -> T;
    
    var body: some View {
        if let data = data {
            content(data)
        }
        else {
            VStack {
                Spacer()
                Text("Loading")
                ProgressView()
                    .progressViewStyle(.linear)
                Spacer()
            }.task {
                let result = try? await self.task();
                
                await MainActor.run {
                    withAnimation {
                        self.data = result;
                    }
                }
            }
        }
    }
}

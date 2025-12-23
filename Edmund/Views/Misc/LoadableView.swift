//
//  LoadableView.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/26/25.
//

import SwiftUI
import os

struct LoadableView<T, Body> : View where Body: View, T: Sendable {
    init(_ data: Binding<T?>, process: @Sendable @escaping () async throws -> T, @ViewBuilder onLoad: @escaping (T) -> Body) {
        self._data = data;
        self.content = onLoad;
        self.task = process;
    }
    
    @Binding private var data: T?;
    private var content: (T) -> Body;
    private var task: () async throws -> T;
    @State private var error = false;
    @Environment(\.loggerSystem) private var logger;
    
    var body: some View {
        if error {
            VStack {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .resizable(resizingMode: .stretch)
                    .frame(width: 30, height: 30)
                Text("Whoops!")
                    .font(.headline)
                Text("An error occured and the data could not be loaded.")
                Spacer()
            }.padding()
        }
        else if let data = data {
            content(data)
        }
        else {
            VStack {
                Spacer()
                Text("Loading")
                ProgressView()
                    .progressViewStyle(.linear)
                Spacer()
            }.padding()
                .task {
                let result: T;
                do {
                    result = try await self.task()
                }
                catch let e {
                    logger?.data.error("Unable to run background processing: \(e.localizedDescription)");
                    await MainActor.run {
                        withAnimation {
                            error = true;
                        }
                    }
                    return;
                }
                
                await MainActor.run {
                    withAnimation {
                        self.data = result;
                    }
                }
            }
        }
    }
}

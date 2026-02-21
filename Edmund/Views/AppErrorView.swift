//
//  AppErrorView.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/5/25.
//

import SwiftUI
import SwiftData

public let bugFormLink: URL = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSc4KedjEgIuSnzqhHv6onfxKZZtLlnj3d5kXLJGaOFu70a9Yg/viewform?usp=header")!
public let featureFormLink: URL = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSewKses93mZERpF5LTmZwnEMhRyyS8p1XQ4_yUnYfgDpuEjhg/viewform?usp=sharing&ouid=107738640373490198091")!

struct AppErrorView : View {
    let error: AppLoadError;
    let state: AppLoadingState;
    
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
    
    @Environment(\.openURL) private var openURL;
    @Environment(\.appLoader) private var appLoader;
    @State private var errorMsg: String = "";
    @State private var showError: Bool = false;
    
    private func reload() {
        if let loader = appLoader {
            Task {
                await loader.reset()
                await loader.loadApp(state: state)
            }
        }
    }
    private func wipe() {
        // TODO: Implement wipe properly
        
        fatalError()
    }
    private func report() {
        openURL(bugFormLink)
    }
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 100)
            Text("Oops!")
                .font(.title)
                .padding(.bottom)
            
            Text("Edmund has hit a snag while loading, and cannot access your data.")
            Text("Please report this issue.")
                .padding(.bottom)
            
            HStack {
                Button {
                    report()
                } label: {
                    Label("Report Issue", systemImage: "exclamationmark.bubble")
                }
                
                Button {
                    wipe()
                } label: {
                    Label("Wipe All Data", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                /*
                 #if DEBUG
                 .disabled(true)
                 #endif
                 */
            }
            
            Divider()
            
            Grid {
                GridRow {
                    Text("Error Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        switch error.with {
                            case .categories: Text("The categories context cannot be loaded.")
                            case .container: Text("The app's model container could not be loaded.")
                        }
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Error Message:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(error.message)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
            
            Spacer()
        }.padding()
            .frame(minWidth: 200)
    }
}

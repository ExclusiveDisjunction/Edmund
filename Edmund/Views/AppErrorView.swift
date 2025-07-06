//
//  AppErrorView.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/5/25.
//

import SwiftUI

struct AppErrorView : View {
    let error: AppLoadError;
    
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
    
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
                    
                } label: {
                    Label("Report Issue", systemImage: "exclamationmark.bubble")
                }
                
                Button {
                    
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    
                } label: {
                    Label("Wipe All Data", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
            
            Divider()
            
            Grid {
                GridRow {
                    Text("Error Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        switch error.with {
                            case .categories: Text("The categories context cannot be loaded.")
                            case .modelContainer: Text("The app's model container could not be loaded.")
                            case .unique: Text("The unique engine could not be loaded.")
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

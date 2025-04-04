//
//  Help.swift
//  Edmund
//
//  Created by Hollan on 4/4/25.
//

import SwiftUI

struct HelpView : View {
    
    var body: some View {
        NavigationSplitView {
            
        } detail: {
            Text("Please select a topic to begin").font(.headline).italic()
        }
    }
}

#Preview {
    HelpView()
}

//
//  ExportViewer.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/10/25.
//

import SwiftUI

struct ExportViewer : View {
    
    let document: EdmundExportDocument<EdmundExportV1>;
    
    var body: some View {
        VStack {
            HStack {
                Text("Export Contents")
                    .font(.title)
                Spacer()
            }
            
            
        }.padding()
    }
}

#Preview {
    ExportViewer(document: .init(from: .debugExample!))
}

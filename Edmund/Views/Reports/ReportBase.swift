//
//  Reports.swift
//  Edmund
//
//  Created by Hollan on 5/1/25.
//

import CoreFoundation
import Foundation
import SwiftUI

enum ReportType: Int, CaseIterable, Hashable, Codable {
    case spending, balances, transactions, income
    
    var title: LocalizedStringKey {
        switch self {
            case .spending: "Spending Report"
            case .balances: "Balances Report"
            case .transactions: "Transactions Report"
            case .income: "Income Report"
        }
    }
}

/*
func saveFilePicker() -> URL? {
    let panel = NSSavePanel()
    panel.title = "Choose a export path"
    panel.isExtensionHidden = false
    panel.canCreateDirectories = true
    panel.allowedContentTypes = [.pdf];
    
    let response = panel.runModal()
    return response == .OK ? panel.url : nil
}
*/

struct ReportBase : View {
    let kind: ReportType;
    
    @State private var showExport = false;
    @Environment(\.dismiss) private var dismiss;
    
    private func export<T: View>(view: T, url: URL) {
        let renderer = ImageRenderer(content: view)
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            //THought process
            //Need document to use file export -> Need output to make document -> Need mutable data to make content -> cant make mutable content... research needed.
            
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
    
            pdf.beginPDFPage(nil)
            
            context(pdf)
            
            pdf.endPDFPage()
            pdf.closePDF()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        Text("Work in progress")
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(kind.title)
                    .font(.title)
                Spacer()
            }
            
            GeometryReader { geometry in
                ScrollView {
                    content
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }.padding()
                .background(RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                    .fill(.background.tertiary))
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Export as PDF", action: {
                    showExport = true
                })
                Button("Ok", action: {
                    dismiss()
                }).buttonStyle(.borderedProminent)
            }
        }.padding()
            /*.fileExporter(isPresented: $showExport, item:  contentTypes: [.pdf]) { url in
                
            }*/
    }
}

#Preview {
    ReportBase(kind: .spending)
}

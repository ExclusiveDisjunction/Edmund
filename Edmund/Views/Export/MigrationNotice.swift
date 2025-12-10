//
//  MigrationNotice.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/10/25.
//

import SwiftUI

public struct MigrationNotice : View {
    @State private var showingExporter = false;
    @State private var exporting = false;
    @State private var document: EdmundExportDocument<EdmundExportV1>? = nil;
    @State private var hadError = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.loggerSystem) private var logger;
    
    private func export() async {
        do {
            let container = modelContext.container;
            
            exporting = true;
            let content = try await Task(priority: .medium) {
                return try EdmundExportV1(from: container)
            }.value;
            
            exporting = false;
            document = .init(from: content);
            showingExporter = true;
        }
        catch let e {
            exporting = false;
            hadError = true;
            logger?.data.error("Unable to export data: \(e).");
        }
    }
    
   public var body: some View {
        VStack {
           Text("Edmund is Updating!")
                .font(.title2)
            
            Text("The next version of Edmund will not be able to use the current data you have.")
            Text("To keep your data, please export your data here, and then import it after updating.")
            
            Button {
                Task(priority: .high) { @MainActor in
                    await self.export()
                }
            } label: {
                Label("Export My Data", systemImage: "square.and.arrow.up")
            }
        }.padding()
           .navigationTitle("Update Notice")
           .sheet(isPresented: $exporting) {
               VStack {
                   Text("Exporting data, please wait.");
                   ProgressView()
                       .progressViewStyle(.linear)
               }.padding();
           }
           .alert("Unable to Export!", isPresented: $hadError) {
               Button("Ok") { hadError = false }
           } message: {
               Text("The data could not be exported.")
           }
           .fileExporter(isPresented: $showingExporter, document: document, contentType: .edmundExport, defaultFilename: "Export \(Date.now.formatted(date: .numeric, time: .omitted))", onCompletion: { result in
               if case let .failure(value) = result {
                   hadError = true;
                   logger?.data.error("Unable to export data: \(value).");
               }
               else if case let .success(value) = result {
                   logger?.data.info("Exported properly to path \(value, privacy: .private)")
               }
           })
    }
}

#Preview {
    MigrationNotice()
}

//
//  Welcome.swift
//  Edmund
//
//  Created by Hollan on 1/9/25.
//

import SwiftUI

struct Welcome : View {
    
    @State private var new_doc: Bool = false
    @State private var showing_import: Bool = false;
    @State private var alert: AlertContext = .init()
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.dismiss) private var dismiss;
    
    private func new_document() {
        new_doc = true;
        showing_import = true;
    }
    private func open_document() {
        new_doc = false;
        showing_import = true;
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("Edmund").font(.title)
                Text("Please create a new document or open an existing one").font(.subheadline)
                Spacer()
            }
            VStack {
                Button("New", action: new_document).buttonStyle(.borderedProminent)
                Button("Open", action: open_document)
                Spacer()
            }
        }.fileImporter(
            isPresented: $showing_import,
            allowedContentTypes: [.edmund_doc],
            allowsMultipleSelection: false,
            onCompletion: { result in
                switch result {
                case .success(let url):
                    break
                case .failure(let error):
                    alert = .init("Unable to open file because '\(error.localizedDescription)'")
                }
        }).alert(alert.is_error ? "Error" : "Notice", isPresented: $alert.show_alert) {
            Text(alert.message)
            Button("Ok", action: { alert.show_alert = false }).buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    Welcome()
}

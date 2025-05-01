//
//  About.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/1/25.
//

import SwiftUI

struct AboutView : View {
    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Unknown"
    }
    private var buildNumber: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "Unknown"
    }
    
    var body: some View {
        VStack {
            Text("Edmund")
                .font(.title)
            Text("Version \(appVersion)")
                .font(.subheadline)
            Text("Build \(buildNumber)")
                .font(.subheadline)
            
            Divider()
            
            Text("Written by Hollan Sellars (ExDisj)")
            Text("Please visit the project on GitHub:")
            Text("https://github.com/ExclusiveDisjunction/Edmund")
            Divider()
            Text("Bug? Feature Request? Concerns?")
            Text("Please submit an issue on GitHub, or contact the developer at exdisj@icloud.com")
            Divider()
            Text("Special Thanks To:")
                .font(.headline)
            HStack {
                VStack {
                    Text("Maks Kruc")
                    Text("James Larson")
                }
                VStack {
                    Text("Ruth")
                    Text("Kyle Lawrence")
                }
            }
            
            Divider()
            Text("Disclosures")
                .font(.headline)
            Text("This app is not translated with professional translators.")
            Text("Please report any translation errors.")
            Text("This app is released as open source, but only the developer, Hollan Sellars, is authorized to publish it.")
                .fixedSize(horizontal: true, vertical: false)
            
            Divider()
            Text("Supporting Projects")
                .font(.headline)
            Grid {
                GridRow {
                    Text("Swift-Markdown-UI")
                    Text("https://github.com/swiftlang/swift-markdown")
                }
            }
        }.padding()
    }
}

#Preview {
    AboutView()
}

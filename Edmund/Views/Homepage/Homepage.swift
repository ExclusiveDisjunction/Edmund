//
//  Homepage.swift
//  Edmund
//
//  Created by Hollan on 1/1/25.
//

import SwiftUI;
import SwiftData;
import EdmundCore

struct Homepage : View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openURL) private var openURL;
    @State private var modifyHomescreen = false;
    
    #if os(iOS)
    @State private var helpBinding: Bool = false;
    @State private var settingsBinding: Bool = false;
    #endif
    
#if os(macOS)
    @Environment(\.openSettings) private var openSettings;
#endif
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("homeMajor") private var major: MajorHomepageOrder = .vSplit;
    @AppStorage("sectorA") private var sectorA: MinorHomepageOrder = .half;
    @AppStorage("sectorB") private var sectorB: MinorHomepageOrder = .full;
    @AppStorage("sectorA1") private var sectorA1: WidgetChoice = .bills;
    @AppStorage("sectorA2") private var sectorA2: WidgetChoice = .moneyGraph;
    @AppStorage("sectorB1") private var sectorB1: WidgetChoice = .simpleBalances;
    @AppStorage("sectorB2") private var sectorB2: WidgetChoice = .spendingGraph;
    
    private func showSettings() {
#if os(macOS)
        openSettings()
#else
        settingsBinding = true
#endif
    }
    private func showHelp() {
#if os(macOS)
        openWindow(id: "help")
#else
        helpBinding = true
#endif
    }
    
    @ViewBuilder
    private var scrollView : some View {
        VStack {
            ChoiceRenderer(choice: sectorA1)
            ChoiceRenderer(choice: sectorA2)
        }
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                scrollView
            }
            else {
                switch major {
                    case .compact:
                        scrollView
                    case .fullScreen:
                        ChoiceRenderer(choice: sectorA1)
                    case .hSplit:
                        VStack(spacing: 10) {
                            SplitChoiceRenderer(kind: .vSplit, minor: sectorA, sectorA: sectorA1, sectorB: sectorA2)
                            SplitChoiceRenderer(kind: .vSplit, minor: sectorB, sectorA: sectorB1, sectorB: sectorB2)
                        }.padding()
                            .background(RoundedRectangle(
                                cornerSize: CGSize(
                                    width: 12,
                                    height: 12
                                )
                            ).fill(.background.tertiary)
                            )
                    case .vSplit:
                        HStack(spacing: 10) {
                            SplitChoiceRenderer(kind: .hSplit, minor: sectorA, sectorA: sectorA1, sectorB: sectorA2)
                            SplitChoiceRenderer(kind: .hSplit, minor: sectorB, sectorA: sectorB1, sectorB: sectorB2)
                        }.padding()
                            .background(RoundedRectangle(
                                cornerSize: CGSize(
                                    width: 12,
                                    height: 12
                                )
                            ).fill(.background.tertiary)
                        )
                }
            }
        }.navigationTitle("Welcome")
            .padding()
            .toolbar {
                Button(action: { modifyHomescreen = true } ) {
                    Label("Customize", systemImage: "rectangle.3.group")
                }
                Button(action: showSettings) {
                    Label("Settings", systemImage: "gear")
                }
                
                #if os(iOS)
                Menu {
                    Button(action: showHelp) {
                        Label("Help", systemImage: "questionmark")
                    }
                    
                    Button {
                        openURL(bugFormLink)
                    } label: {
                        Label("Report a bug", systemImage: "ladybug")
                    }
                    
                    Button {
                        openURL(featureFormLink)
                    } label: {
                        Label("Request a feature", systemImage: "lightbulb.max")
                    }
                } label: {
                    Label("Help", systemImage: "questionmark")
                }
                #else
                Button(action: showHelp) {
                    Label("Help", systemImage: "questionmark")
                }
                #endif
            }
            .sheet(isPresented: $modifyHomescreen) {
                HomepageEditor(isSheet: true)
                    .padding()
            }
        #if os(iOS)
            .sheet(isPresented: $helpBinding) {
                HelpTreePresenter()
            }.sheet(isPresented: $settingsBinding) {
                SettingsView()
            }
        #endif
    }
}


#Preview {
    DebugContainerView {
        Homepage()
            .frame(width: 600, height: 400)
            .padding()
    }
}

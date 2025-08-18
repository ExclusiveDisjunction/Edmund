//
//  HomepageEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI;

enum MajorHomepageOrder : Int, CaseIterable, Identifiable, Codable {
    case vSplit, hSplit, fullScreen, compact
    
    var name: LocalizedStringKey {
        switch self {
            case .vSplit:     "Vertical Split"
            case .hSplit:     "Horizontal Split"
            case .fullScreen: "Full Screen"
            case .compact:    "Compact"
        }
    }
    var desc: LocalizedStringKey {
        switch self {
            case .vSplit: "Split the homepage vertically"
            case .hSplit: "Split the homepage horizontally"
            case .fullScreen: "Display the homepage as one widget"
            case .compact: "Display the homepage as two widgets"
        }
    }
    var id: Self { self }
}
enum MinorHomepageOrder : Int, CaseIterable, Identifiable, Codable {
    case full, half
    
    var name: LocalizedStringKey {
        switch self {
            case .full: "One Section"
            case .half: "Two Sections"
        }
    }
    var desc: LocalizedStringKey {
        switch self {
            case .full: "Use the space for only one widget"
            case .half: "Use the space for two widgets"
        }
    }
    
    var id: Self { self }
}

struct HomepageEditor : View {
    let isSheet: Bool;
    
    @AppStorage("homeMajor") private var major: MajorHomepageOrder = .vSplit;
    @AppStorage("sectorA") private var sectorA: MinorHomepageOrder = .half;
    @AppStorage("sectorB") private var sectorB: MinorHomepageOrder = .full;
    @AppStorage("sectorA1") private var sectorA1: WidgetChoice = .bills;
    @AppStorage("sectorA2") private var sectorA2: WidgetChoice = .moneyGraph;
    @AppStorage("sectorB1") private var sectorB1: WidgetChoice = .simpleBalances;
    @AppStorage("sectorB2") private var sectorB2: WidgetChoice = .spendingGraph;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @ViewBuilder
    private var scrollDisplay: some View {
        VStack {
            ChoicePicker(choice: $sectorA1)
            ChoicePicker(choice: $sectorA2)
        }
    }
    @ViewBuilder
    private var fullDisplay: some View {
        ChoicePicker(choice: $sectorA1)
    }
    @ViewBuilder
    private var hSplitDisplay: some View {
        GeometryReader { geometry in
            VStack {
                SplitChoicePicker(kind: .vSplit, minor: sectorA, sectorA: $sectorA1, sectorB: $sectorA2)
                    .frame(width: geometry.size.width, height: geometry.size.height / 2)
                SplitChoicePicker(kind: .vSplit, minor: sectorB, sectorA: $sectorB1, sectorB: $sectorB2)
                    .frame(width: geometry.size.width, height: geometry.size.height / 2)
            }
        }
    }
    @ViewBuilder
    private var vSplitDisplay: some View {
        GeometryReader { geometry in
            HStack {
                SplitChoicePicker(kind: .hSplit, minor: sectorA, sectorA: $sectorA1, sectorB: $sectorA2)
                    .frame(width: geometry.size.width / 2, height: geometry.size.height)
                SplitChoicePicker(kind: .hSplit, minor: sectorB, sectorA: $sectorB1, sectorB: $sectorB2)
                    .frame(width: geometry.size.width / 2, height: geometry.size.height)
            }
        }
    }
    
    var body: some View {
        VStack {
            if isSheet {
                HStack {
                    Text("Homepage Organizer")
                        .font(.title)
                    Spacer()
                }
            }
            
            if horizontalSizeClass == .compact {
                HStack {
                    Label("iOS & iPadOS (vertical orientations) only display in Compact mode.", systemImage: "info.circle")
                        .italic()
                    Spacer()
                }
            }
            
            Picker("", selection: $major) {
                ForEach(MajorHomepageOrder.allCases, id: \.id) { order in
                    Text(order.name).tag(order)
                }
            }.labelsHidden()
                .pickerStyle(.segmented)
            
            if major == .hSplit || major == .vSplit {
                HStack {
                    VStack {
                        Text(major == .hSplit ? "Top Section" : "Left Side")
                        
                        Picker("", selection: $sectorA) {
                            ForEach(MinorHomepageOrder.allCases, id: \.id) { order in
                                Text(order.name).tag(order)
                            }
                        }.pickerStyle(.segmented)
                            .labelsHidden()
                    }
                    
                    VStack {
                        Text(major == .hSplit ? "Bottom Section" : "Right Side")
                        Picker("", selection: $sectorB) {
                            ForEach(MinorHomepageOrder.allCases, id: \.id) { order in
                                Text(order.name).tag(order)
                            }
                        }.pickerStyle(.segmented)
                    }
                }
            }
            
            Divider()
            
            switch major {
                case .compact: scrollDisplay
                case .fullScreen: fullDisplay
                case .vSplit: vSplitDisplay
                case .hSplit: hSplitDisplay
            }
            
            Spacer()
            
            if isSheet {
                HStack {
                    Spacer()
                    Button("Ok", action: { dismiss() })
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        #if os(macOS)
            .frame(height: 450)
        #endif

    }
}

#Preview {
    HomepageEditor(isSheet: false)
        .padding()
}

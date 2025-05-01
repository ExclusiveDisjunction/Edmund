//
//  HomepageEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI;

enum MajorHomepageOrder : Int, CaseIterable, Identifiable, Codable {
    case vSplit, hSplit, fullScreen, scroll
    
    var name: LocalizedStringKey {
        switch self {
            case .vSplit:     "Vertical Split"
            case .hSplit:     "Horizontal Split"
            case .fullScreen: "Full Screen"
            case .scroll:     "Scroll"
        }
    }
    var desc: LocalizedStringKey {
        switch self {
            case .vSplit: "Split the homepage vertically"
            case .hSplit: "Split the homepage horizontally"
            case .fullScreen: "Display the homepage as one widget"
            case .scroll: "Display the homepage as a scrollable page (iOS Default)"
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
    @AppStorage("homeMajor") private var major: MajorHomepageOrder = .vSplit;
    @AppStorage("sectorA") private var sectorA: MinorHomepageOrder = .half;
    @AppStorage("sectorB") private var sectorB: MinorHomepageOrder = .full;
    @AppStorage("sectorA1") private var sectorA1: WidgetChoice = .bills;
    @AppStorage("sectorA2") private var sectorA2: WidgetChoice = .payday;
    @AppStorage("sectorB1") private var sectorB1: WidgetChoice = .simpleBalances;
    @AppStorage("sectorB2") private var sectorB2: WidgetChoice = .spendingGraph;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
#if os(macOS)
    private let minWidth: CGFloat = 60;
    private let maxWidth: CGFloat = 70;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#endif
    
    @ViewBuilder
    private var scrollDisplay: some View {
        VStack {
            ChoicePicker(choice: $sectorA1)
            ChoicePicker(choice: $sectorA2)
            ChoicePicker(choice: $sectorB1)
            ChoicePicker(choice: $sectorB2)
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
            HStack {
                Text("Homepage Organizer")
                    .font(.title)
                Spacer()
            }
            if horizontalSizeClass == .compact {
                HStack {
                    Label("Compact sizes only display scroll view.", systemImage: "info.circle")
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
            
            /*
             if major == .hSplit || major == .vSplit {
             GridRow {
             Text(major == .hSplit ? "Top Section" : "Left Side")
             .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
             
             HStack {
             Picker("", selection: $sectorA) {
             ForEach(MinorHomepageOrder.allCases, id: \.id) { order in
             Text(order.name).tag(order)
             }
             }.labelsHidden()
             .pickerStyle(.segmented)
             Spacer()
             }
             }
             GridRow {
             
             Spacer()
             }
             }
             
             
             }
             */
            
            switch major {
                case .scroll: scrollDisplay
                case .fullScreen: fullDisplay
                case .vSplit: vSplitDisplay
                case .hSplit: hSplitDisplay
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() })
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
        #if os(macOS)
            .frame(height: 450)
        #endif

    }
}

#Preview {
    HomepageEditor()
        .padding()
}

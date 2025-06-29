//
//  BudgetEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

struct BudgetPropertiesEditor : View {
    @Bindable var snapshot: BudgetInstanceSnapshot;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#endif
    
    var body: some View {
        Grid {
            GridRow {
                Text("Name:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("", text: $snapshot.name)
            }
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                CurrencyField(snapshot.amount)
            }
            
            GridRow {
                Text("Income Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                Picker("", selection: $snapshot.kind) {
                    ForEach(IncomeKind.allCases, id: \.id) { kind in
                        Text(kind.display).tag(kind)
                    }
                }.pickerStyle(.segmented)
                    .labelsHidden()
            }
            
            GridRow {
                Text("Deposit to:")
                
                NamedPairPicker($snapshot.depositTo)
            }
        }.padding()
    }
}

struct BudgetRemainderEditor : View {
    @Bindable var remainder: DevotionSnapshotBase;
    @Binding var hasRemainder: Bool;
    var remainderValue: Decimal;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    var body: some View {
        Grid {
            GridRow {
                Text("Use Remainder:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Toggle("", isOn: $hasRemainder)
                        .labelsHidden()
                    
                    TooltipButton("When this is on, any remaining balance not used by other devotions will be used here.")
                    Spacer()
                }
            }
            
            if hasRemainder {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("", text: $remainder.name)
                }
                
                GridRow {
                    Text("Group:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $remainder.group) {
                        ForEach(DevotionGroup.allCases) { group in
                            Text(group.display).tag(group)
                        }
                    }.labelsHidden()
                }
                
                GridRow {
                    Text("Account:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($remainder.account)
                }
                
                GridRow {
                    Text("Used Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(remainderValue, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
            }
        }.padding()
    }
}

struct BudgetDevotionsEditor : View {
    @Bindable var snapshot: BudgetInstanceSnapshot;
    @State private var selection: Set<AnyDevotionSnapshot.ID> = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var compact: some View {
        List($snapshot.devotions, selection: $selection) { $devotion in
            
        }
    }
    
    @ViewBuilder
    private var fullSize: some View {
        Table($snapshot.devotions, selection: $selection) {
            TableColumn("Name") { $dev in
                TextField("", text: $dev.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            TableColumn("Devotion") { $dev in
                switch dev {
                    case .amount(let a): CurrencyField(a.amount)
                    case .percent(let p): PercentField(p.amount)
                }
            }
            
            TableColumn("Amount") { $dev in
                switch dev {
                    case .amount(let a): Text(a.amount.rawValue, format: .currency(code: currencyCode))
                    case .percent(let p): Text(p.amount.rawValue * snapshot.amount.rawValue, format: .currency(code: currencyCode))
                }
            }
            
            TableColumn("Group") { $dev in
                Picker("", selection: $dev.group) {
                    ForEach(DevotionGroup.allCases) { group in
                        Text(group.display).tag(group)
                    }
                }
            }
            
            TableColumn("Destination") { $dev in
                NamedPairPicker($dev.account)
            }
            .width(160)
        }
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            compact
                .frame(minHeight: 200)
                .padding()
        }
        else {
            fullSize
                .frame(minHeight: 200)
                .padding()
        }
    }
}

struct BudgetEditor : View {
    init(_ data: BudgetInstance?) {
        let snapshot: BudgetInstanceSnapshot;
        if let data = data {
            snapshot = .init(data)
        }
        else {
            snapshot = .init()
        }
        
        self.snapshot = snapshot
        self.hash = snapshot.hashValue
    }
    
    private let hash: Int;
    @Bindable private var snapshot: BudgetInstanceSnapshot;
    
    private func cancel() {
        
    }
    private func submit() {
        
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Budget Editor")
                    .font(.title2)
                
                Spacer()
            }
            
            ScrollView {
                TabView {
                    BudgetPropertiesEditor(snapshot: snapshot)
                        .tabItem {
                            Text("Properties")
                        }
                    
                    BudgetDevotionsEditor(snapshot: snapshot)
                        .tabItem {
                            Text("Devotions")
                        }
                    
                    BudgetRemainderEditor(remainder: snapshot.remainder, hasRemainder: $snapshot.hasRemainder, remainderValue: snapshot.remainderValue)
                        .tabItem {
                            Text("Remainder")
                        }
                    
                    
                }
            }.frame(minHeight: 250)
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel", action: cancel)
                    .buttonStyle(.bordered)
                
                Button("Ok", action: submit)
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
            .frame(idealWidth: 500, idealHeight: 400)
    }
}

#Preview {
    let container = Containers.debugContainer;
    let item = (try! container.mainContext.fetch(FetchDescriptor<BudgetInstance>())).first!
    BudgetEditor(item)
        .modelContainer(Containers.debugContainer)
}

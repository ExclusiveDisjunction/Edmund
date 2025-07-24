//
//  BudgetDevotionsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDevotionsEditor : View {
    @Bindable var snapshot: IncomeDivisionSnapshot;
    @State private var closeLook: AnyDevotionSnapshot?;
    @State private var selection: Set<AnyDevotionSnapshot.ID> = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private func amountFor(_ dev: AnyDevotionSnapshot) -> some View {
        switch dev {
            case .amount(let a): Text(a.amount.rawValue, format: .currency(code: currencyCode))
            case .percent(let p): Text(p.amount.rawValue * snapshot.amount.rawValue, format: .currency(code: currencyCode))
            default: Text("internalError")
        }
    }
    
    private func removeSelected(_ selection: Set<AnyDevotionSnapshot.ID>? = nil) {
        let trueSelection = selection == nil ? self.selection : selection!;
        
        withAnimation {
            snapshot.devotions.removeAll(where: { trueSelection.contains($0.id) } )
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Income:")
                Text(snapshot.amount.rawValue, format: .currency(code: currencyCode))
                
                Spacer()
                
                if horizontalSizeClass != .compact {
                    Text("Remainder Amount:")
                    Text(snapshot.remainderValue, format: .currency(code: currencyCode))
                }
                
                Text("Amount Free:")
                    .bold()
                Text(snapshot.moneyLeft, format: .currency(code: currencyCode))
                    .bold()
                
                Button {
                    withAnimation {
                        snapshot.devotions.append(.amount(.init()))
                    }
                } label: {
                    Image(systemName: "dollarsign")
                }.buttonStyle(.borderless)
                
                Button {
                    withAnimation {
                        snapshot.devotions.append(.percent(.init()))
                    }
                } label: {
                    Image(systemName: "percent")
                }.buttonStyle(.borderless)
                 
                Button {
                    removeSelected()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }.buttonStyle(.borderless)
                
                #if os(iOS)
                EditButton()
                #endif
            }
            
            Table($snapshot.devotions, selection: $selection) {
                TableColumn(horizontalSizeClass == .compact ? "Devotion" : "Name") { $dev in
                    if horizontalSizeClass == .compact {
                        HStack {
                            TextField("Name", text: $dev.name)
                                .textFieldStyle(.roundedBorder)
                            
                            Spacer()
                            
                            amountFor(dev)
                        }.swipeActions(edge: .trailing) {
                            Button {
                                closeLook = dev
                            } label: {
                                Label("Close Look", systemImage: "magnifyingglass")
                            }
                        }
                    }
                    else {
                        TextField("Name", text: $dev.name)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                TableColumn("Devotion") { $dev in
                    switch dev {
                        case .amount(let a): CurrencyField(a.amount)
                        case .percent(let p): PercentField(p.amount)
                        default: Text("internalError")
                    }
                }
                
                TableColumn("Amount") { $dev in
                    amountFor(dev)
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
                .width(270)
            }.contextMenu(forSelectionType: AnyDevotionSnapshot.ID.self) { selection in
                Button {
                    if let id = selection.first, let element = snapshot.devotions.first(where: { $0.id == id } ), selection.count == 1 {
                        closeLook = element;
                    }
                } label: {
                    Label("Close Look", systemImage: "magnifyingglass")
                }.disabled(selection.count != 1)
                
                Button {
                    removeSelected(selection)
                } label: {
                    Label("Remove", systemImage: "trash")
                        .foregroundStyle(.red)
                }.disabled(selection.isEmpty)
            }
        }.sheet(item: $closeLook) { devotion in
            AnyDevotionSnapshotCloseLook(snapshot: snapshot, devotion: devotion)
        }
    }
}

#Preview {
    DebugContainerView {
        IncomeDevotionsEditor(snapshot: try! IncomeDivision.getExampleBudget().makeSnapshot())
            .padding()
    }
}

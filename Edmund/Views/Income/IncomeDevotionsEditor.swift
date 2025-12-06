//
//  BudgetDevotionsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

struct IncomeDevotionsEditor : View {
    @Bindable var snapshot: IncomeDivisionSnapshot;
    @State private var closeLook: IncomeDevotionSnapshot?;
    @State private var selection: Set<IncomeDevotionSnapshot.ID> = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private func amountFor(_ dev: IncomeDevotionSnapshot) -> some View {
        let amount = switch dev.kind {
            case .amount(let a): a.rawValue
            case .percent(let p): p.rawValue * snapshot.amount.rawValue
            case .remainder: snapshot.perRemainderAmount
        }
        
        Text(amount, format: .currency(code: currencyCode))
    }
    
    private func removeSelected(_ selection: Set<IncomeDevotionSnapshot.ID>? = nil) {
        let trueSelection = selection == nil ? self.selection : selection!;
        
        withAnimation {
            snapshot.devotions.removeAll(where: { trueSelection.contains($0.id) } )
        }
    }
    
    @ViewBuilder
    private var headerRow : some View {
        HStack {
            Text("Income:")
            Text(snapshot.amount.rawValue, format: .currency(code: currencyCode))
            Spacer()
        }
        
        HStack {
            Label("Remainder Total:", systemImage: "dollarsign.ring.dashed")
            Text(snapshot.remainderTotal, format: .currency(code: currencyCode))
            
            if horizontalSizeClass == .compact {
                Spacer()
            }
        }
        
        HStack {
            Text("Money Left:")
                .bold()
            Text(snapshot.moneyLeft, format: .currency(code: currencyCode))
                .bold()
            
            if horizontalSizeClass == .compact {
                Spacer()
            }
        }
        
        HStack {
            if horizontalSizeClass == .compact {
                Spacer()
            }
            
            Button {
                withAnimation {
                    snapshot.devotions.append(.newBlankAmount())
                }
            } label: {
                Image(systemName: "dollarsign")
            }.buttonStyle(.borderless)
            
            Button {
                withAnimation {
                    snapshot.devotions.append(.newBlankPercent())
                }
            } label: {
                Image(systemName: "percent")
            }.buttonStyle(.borderless)
            
            Button {
                withAnimation {
                    snapshot.devotions.append(.newBlankPercent())
                }
            } label: {
                Image(systemName: "dollarsign.ring.dashed")
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
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                VStack {
                    headerRow
                }
            }
            else {
                HStack {
                    headerRow
                }
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
                            }.tint(.green)
                        }
                    }
                    else {
                        TextField("Name", text: $dev.name)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                TableColumn("Devotion") { $dev in
                    switch dev.kind {
                        case .amount(let a): CurrencyField(a)
                        case .percent(let p): PercentField(p)
                        case .remainder: Text("-")
                    }
                }
                
                TableColumn("Amount") { $dev in
                    amountFor(dev)
                }
                
                TableColumn("Group") { $dev in
                    EnumPicker(value: $dev.group)
                }
                
                TableColumn("Destination") { $dev in
                    ElementPicker($dev.account)
                }
                .width(270)
            }.contextMenu(forSelectionType: UUID.self) { selection in
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
            DevotionSnapshotCloseLook(snapshot: snapshot, devotion: devotion)
        }
    }
}

#Preview {
    @Previewable @Query var income: [IncomeDivision];
    DebugContainerView {
        IncomeDevotionsEditor(snapshot: income[0].makeSnapshot())
            .padding()
    }
}

//
//  LedgerEntryVE.swift
//  Edmund
//
//  Created by Hollan on 4/1/25.
//

import SwiftUI
import SwiftData

struct LedgerEntryVE : View {
    
    @Bindable var target: LedgerEntry;
    @State private var isEdit: Bool;
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    
#if os(macOS)
    let labelMinWidth: CGFloat = 60;
    let labelMaxWidth: CGFloat = 70;
#else
    let labelMinWidth: CGFloat = 80;
    let labelMaxWidth: CGFloat = 85;
#endif
    
    init(_ entry: LedgerEntry, isEdit: Bool = false) {
        self.target = entry
        self.isEdit = isEdit
    }
    
    private func toggleEdit() {
        isEdit.toggle()
    }
    
    
    var body: some View {
        VStack {
            Text(target.memo).font(.title2)
            Button(action: toggleEdit) {
                Image(systemName: isEdit ? "info.circle" : "pencil").resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.accent)
#if os(iOS)
                .padding(.trailing)
#endif
            
            Divider().padding([.top, .bottom])
            
            Grid {
                if isEdit {
                    GridRow {
                        Text("Memo:")
                            .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                        TextField("Name", text: $target.memo).textFieldStyle(.roundedBorder)
                    }
                    
                }
                
                if ledgerStyle != .none || isEdit {
                    GridRow {
                        Text(ledgerStyle == .none ? "Money In:" : ledgerStyle == .standard ? "Debit:" : "Credit:")
                            .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                        
                        HStack {
                            if isEdit {
                                TextField("Credit", value: $target.credit, format: .currency(code: "USD")).textFieldStyle(.roundedBorder)
                            }
                            else {
                                Text(target.credit, format: .currency(code: "USD"))
                            }
                            Spacer()
                        }
                    }
                    GridRow {
                        Text(ledgerStyle == .none ? "Money Out:" : ledgerStyle == .standard ? "Credit:" : "Debit:")
                            .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                        
                        HStack {
                            if isEdit {
                                TextField("Debit", value: $target.debit, format: .currency(code: "USD")).textFieldStyle(.roundedBorder)
                            }
                            else {
                                Text(target.debit, format: .currency(code: "USD"))
                            }
                            Spacer()
                        }
                    }
                }
                GridRow {
                    Text("Balance:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.balance, format: .currency(code: "USD"))
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Date:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if isEdit {
                            DatePicker("Date", selection: $target.date, displayedComponents: .date).labelsHidden()
                        }
                        else {
                            Text(target.date.formatted(date: .abbreviated, time: .omitted))
                        }
                        Spacer()
                    }
                }
                GridRow {
                    Text("Added On:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.added_on.formatted(date: .abbreviated, time: .shortened))
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Location:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if isEdit {
                            TextField("Location", text: $target.location).textFieldStyle(.roundedBorder)
                        }
                        else {
                            Text(target.location)
                        }
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Category:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if isEdit {
                            NamedPairPicker<SubCategory>($target.category)
                        }
                        else {
                            if let cat = target.category {
                                NamedPairViewer(pair: cat)
                            }
                            else {
                                Text("No Category")
                            }
                        }
                        
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Account:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if isEdit {
                            NamedPairPicker($target.account)
                        }
                        else {
                            if let acc = target.account {
                                NamedPairViewer(pair: acc)
                            }
                            else {
                                Text("No Account")
                            }
                        }
                        
                        Spacer()
                    }
                }
                Divider()
            }
            
            Spacer()
        }.padding()
    }
}

#Preview {
    LedgerEntryVE(LedgerEntry.exampleEntry, isEdit: true).modelContainer(Containers.debugContainer)
}

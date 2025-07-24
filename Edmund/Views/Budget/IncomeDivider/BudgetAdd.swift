//
//  BudgetAdd.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/27/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDivisionAdd : View {
    init(_ id: Binding<IncomeDivision.ID?>? = nil) {
        self.id = id;
    }
    
    private let id: Binding<IncomeDivision.ID?>?;
    @State private var name: String = "";
    private var amount: CurrencyValue = .init();
    @State private var deposit: SubAccount? = nil;
    @State private var kind: IncomeKind = .pay;
    
    @State private var submitError = false;
    @State private var createError = false;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    
    private func validate() -> Bool {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return false }
        
        guard deposit != nil else { return false }
        
        guard amount >= 0 else { return false }
        
        return true
    }
    private func create() -> Bool {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard let account = deposit else { return false }
        
        let new = IncomeDivision(name: name, amount: amount.rawValue, kind: kind, depositTo: account)
        modelContext.insert(new)
        if let binding = id {
            binding.wrappedValue = new.id;
        }
        return true;
    }
    private func submit() {
        guard validate() else {
            submitError = true;
            return
        }
        guard create() else {
            createError = true;
            return
        }
        
        dismiss();
    }
    
    var body: some View {
        VStack {
            Text("Add Income Division")
                .font(.title2)
            
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Income:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                GridRow {
                    Text("Income Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $kind) {
                        ForEach(IncomeKind.allCases, id: \.id) { kind in
                            Text(kind.display).tag(kind)
                        }
                    }.pickerStyle(.segmented)
                        .labelsHidden()
                }
                
                GridRow {
                    Text("Deposit Into:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($deposit)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Cancel", action: { dismiss() } )
                    .buttonStyle(.bordered)
                
                Button("Ok", action: submit)
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
            .alert("Error", isPresented: $submitError, actions: {
                Button("Ok", action: { submitError = false } )
            }, message: {
                Text("Please ensure that the name is not empty, the income is not negative, and an account is selected.")
            })
            .alert("Error", isPresented: $createError, actions: {
                Button("Ok", action: { createError = false } )
            }, message: {
                Text("internalError")
            })
    }
}

#Preview {
    DebugContainerView {
        IncomeDivisionAdd()
    }
}

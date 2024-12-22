//
//  BalanceSheet.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

struct BalanceSheet: View {
    init(previewAccounts: [Tender]? = nil) {
        pAccounts = previewAccounts
    }
    
    @Query var qAccounts: [Tender]
    var pAccounts: [Tender]?
    var accounts: [Tender] {
        pAccounts ?? qAccounts
    }
    
    @State private var showZeroes: Bool = true
    @State private var selected: Set<TenderTableRow.ID> = []
    
    var body: some View {
        VStack {
            VStack {
                Text("Balances").font(.largeTitle)
                HStack {
                    Toggle("Show Zeroes", isOn: $showZeroes)
                }
            }
            Table(of: TenderTableRow.self, selection: $selected) {
                
                TableColumn("Name") { row in
                    switch row {
                    case .tender(let account): HStack {
                        if !(account.subTenders?.isEmpty ?? false) {
                            Image(systemName: account.uiExpanded ? "chevron.down" : "chevron.right")
                        }
                        Text(account.name).fontWeight(.bold)
                    } .onTapGesture {
                        withAnimation {
                            if let index = accounts.firstIndex(of: account) {
                                withAnimation() {
                                    accounts[index].uiExpanded.toggle()
                                }
                            }
                        }
                    }
                    case .subTender(let subAccount): Text("\t\(subAccount.name)")
                    }
                }
                TableColumn("Credits") { row in
                    Text(row.computeCredit(), format: .currency(code: "USD"))
                        .foregroundStyle(row.computeCredit() < 0 ? .red : .primary)
                }
                TableColumn("Debits") { row in
                    Text(row.computeDebit(), format: .currency(code: "USD"))
                        .foregroundStyle(row.computeDebit() < 0 ? .red : .primary)
                }
                TableColumn("Balance") { row in
                    Text(row.computeBalance(), format: .currency(code: "USD"))
                        .foregroundStyle(row.computeBalance() < 0 ? .red : .primary)
                }
                
            } rows: {
                ForEach(flattenedAccounts()) { (row: TenderTableRow) in
                    let showZero = (showZeroes || row.computeBalance() != 0) || row.computeBalance() != 0
                    
                    if showZero{
                        TableRow(row).contextMenu {
                            Button(action: {
                                editAccount(row: row)
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(action: {
                                auditAccount(row: row)
                            }) {
                                Label("Audit", systemImage: "exclamationmark.square")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func flattenedAccounts() -> [TenderTableRow] {
        var rows: [TenderTableRow] = []
        
        for account in accounts {
            rows.append(.tender(account))
            if account.uiExpanded && !(account.subTenders?.isEmpty ?? false) {
                rows.append(contentsOf: account.subTenders!.map { .subTender($0) })
            }
        }
        
        return rows
    }
    
    private func editAccount(row: TenderTableRow) -> Void {
        
    }
    private func auditAccount(row: TenderTableRow) -> Void {
        
    }
}

#Preview {
    BalanceSheet(previewAccounts: Tender.exampleTenders)
}

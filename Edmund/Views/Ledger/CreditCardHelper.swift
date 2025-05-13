//
//  BalanceVerification.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData
import EdmundCore

@Observable
class BalanceVerifyRow : Identifiable {
    init(account: Account, balance: Decimal) {
        self.id = UUID();
        self.account = account;
        self.avalibleCredit = account.creditLimit ?? .nan;
        self.balance = balance
    }
    
    let id: UUID
    let account: Account;
    var name: String {
        account.name
    }
    var avalibleCredit: Decimal;
    var creditLimit: Decimal {
        account.creditLimit ?? .nan
    }
    let balance: Decimal;

    var expectedBalance: Decimal {
        creditLimit - avalibleCredit
    }
    var variance: Decimal {
        balance - expectedBalance
    }
}

struct CreditCardHelper: View {
    @Query private var accounts: [Account];
    @State private var manual: Bool = false;
    @State private var rows: [BalanceVerifyRow] = [];
    
    private var shouldShowPopoutButton: Bool {
#if os(macOS)
        return true
#else
        if #available(iOS 16.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        return false
#endif
    }
    
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("showCreditCardHelperTooltip") private var showCreditCardHelperTooltip: Bool = true;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        let balances = BalanceResolver.computeBalances(accounts).filter { $0.key.creditLimit != nil };
        
        self.rows = balances.map { bal in
            BalanceVerifyRow(
                account: bal.key,
                balance: bal.value.1 - bal.value.0
            )
        }
    }
    private func popout() {
        openWindow(id: "creditHelper")
    }
    
    @ViewBuilder
    var expanded: some View {
        Table($rows) {
            TableColumn("Account") { $row in
                Text(row.name)
            }
            TableColumn("Credit Limit") { $row in
                Text(row.creditLimit, format: .currency(code: currencyCode))
            }
            TableColumn("Availiable Credit") { $row in
                TextField("", value: $row.avalibleCredit, format: .currency(code: currencyCode))
                    .textFieldStyle(.roundedBorder)
            }
            TableColumn("Expected Balance") { $row in
                Text(row.expectedBalance, format: .currency(code: currencyCode))
            }
            TableColumn("Current Balance") { $row in
                Text(row.balance, format: .currency(code: currencyCode))
            }
            TableColumn("Variance") { $row in
                Text(row.variance, format: .currency(code: currencyCode))
            }
            TableColumn("Status") { $row in
                Text(row.variance == 0 ? "Balanced" : row.variance > 0 ? "Over" : "Under")
            }
        }.contextMenu(forSelectionType: BalanceVerifyRow.ID.self) { selection in
            
        }
    }
    
    @ViewBuilder
    var compact: some View {
        List($rows) { $row in
            
        }
    }

    var body: some View {
        VStack {
            if showCreditCardHelperTooltip {
                HStack {
                    Text("If you need assistance with this tool, please see the help topic.")
                        .italic()
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showCreditCardHelperTooltip = false
                        }
                    }) {
                        Text("x")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
            
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                expanded
            }
        }.padding()
            .task { refresh() }
            .navigationTitle("Credit Card Helper")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: refresh) {
                        Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                    }
                }
                
                if shouldShowPopoutButton {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: popout) {
                            Label("Open in new Window", systemImage: "rectangle.badge.plus")
                        }
                    }
                }
            }
    }
}

#Preview {
    CreditCardHelper().modelContainer(Containers.debugContainer)
}

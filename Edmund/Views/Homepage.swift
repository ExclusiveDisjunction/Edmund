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
    
    @Query private var accounts: [Account];
    @Query private var bills: [Bill];
    @Query private var utilities: [Utility];
    private var allBills: [any BillBase] {
        bills + utilities
    }
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @State private var loadedBalances: [AccountBalance]? = nil;
    @State private var loadedBills: [UpcomingBill]? = nil;
    
    @ViewBuilder
    private var billsView: some View {
        VStack {
            Text("Upcoming Bills").font(.headline)
            if let loaded = loadedBills {
                List(loaded) { bill in
                    HStack {
                        Text(bill.name)
                        Spacer()
                        Text(bill.amount, format: .currency(code: currencyCode))
                        Text("on", comment: "$_ on [date]")
                        Text(bill.dueDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            else {
                Spacer()
                VStack {
                    Text("Loading")
                    ProgressView()
                }.task {
                    
                    /*
                    await MainActor.run {
                        withAnimation {
                            loadedBills = .init()
                        }
                    }
                     */
                }
                
                Spacer()
            }
        }
    }
    @ViewBuilder
    private var accountsView: some View {
        VStack {
            Text("Account Balances").font(.headline)
            if let balances = loadedBalances {
                List(balances) { account in
                    HStack {
                        Text(account.name)
                        Spacer()
                        Text(account.balance, format: .currency(code: currencyCode))
                            .foregroundStyle(account.balance < 0 ? .red : .primary)
                    }
                }
            }
            else {
                VStack {
                    Text("Loading")
                    ProgressView()
                }.task {
                    let rawBalances = BalanceResolver.computeAccountBalances(accounts);
                    let transformed = rawBalances.map { AccountBalance(name: $0.key.name, credit: $0.value.0, debit: $0.value.1) }.sorted(using: KeyPathComparator(\.balance, order: .reverse))
                    
                    await MainActor.run {
                        withAnimation {
                            loadedBalances = transformed
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func mainContent(horiz: Bool) -> some View {
        if horiz {
            GeometryReader { geometry in
                billsView.frame(width: geometry.size.width)
            }
            
            GeometryReader { geometry in
                accountsView.frame(width: geometry.size.width)
            }
        }
        else {
            billsView.frame(minHeight: 250)
            accountsView.frame(minHeight: 250)
        }
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                VStack(spacing: 10) {
                    mainContent(horiz: false)
                }
            }
            else {
                HStack(spacing: 10) {
                    mainContent(horiz: true)
                }
            }
        }.navigationTitle("Welcome")
            .padding()
    }
}

#Preview {
    Homepage()
}

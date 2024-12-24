//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;

class TransactionError : Error {
    init(kind: Kind, on: String, message: String? = nil) {
        self.kind = kind
        self.on = on;
        self.message = message ??  "";
    }
    
    enum Kind {
        case empty_argument
        case invalid_value
    }
    
    let kind: Kind;
    let on: String;
    let message: String;
}

protocol TransactionBase : View {
    func compile_deltas() -> Dictionary<String, Decimal>;
    func create_transactions() throws(TransactionError) -> [LedgerEntry];
}

struct ManualTransactions: View, TransactionBase {
    private enum AlertState {
        case success(count: Int)
        case failed(reason: String)
    }

    @State private var adding : [LedgerEntry] = [];
    @State private var selected: UUID?;
    @State private var account: String = "";
    @State private var alert_state = AlertState.failed(reason: "");
    @State private var show_alert = false;
    
    private func add_trans() {
        adding.append(LedgerEntry(id: UUID(), memo: "", credit: 0.00, debit: 0.00, date: Date.now, added_on: Date.now, location: "", category: "", sub_category: "", tender: "", sub_tender: ""))
    }
    private func remove_trans() {
        if selected == nil { return }
        adding.removeAll(where: { $0.id == selected })
    }
    private func compile_quick() {
        do {
            let things = try create_transactions();
            alert_state = .success(count: things.count)
            show_alert = true
            
        } catch let e{
            alert_state = .failed(reason: e.localizedDescription)
            show_alert = true
        }
    }
    
    public func compile_deltas() -> Dictionary<String, Decimal> {
        adding.reduce(into: [:]) { $0[$1.tender + "." + $1.sub_tender] = $1.credit - $1.debit }
    }
    public func create_transactions() throws(TransactionError) -> [LedgerEntry] {
        guard !self.account.isEmpty else { throw TransactionError(kind: .empty_argument, on: "Tender") }
        
        for item in adding {
            guard item.memo != "" else { throw TransactionError(kind: .empty_argument, on: "Memo")}
            guard item.location != "" else { throw TransactionError(kind: .empty_argument, on: "Location")}
            guard item.category != "" else { throw TransactionError(kind: .empty_argument, on: "Category")}
            guard item.sub_category != "" else { throw TransactionError(kind: .empty_argument, on: "Sub Category")}
            guard item.sub_tender != "" else { throw TransactionError(kind: .empty_argument, on: "Sub Tender")}
            
            item.tender = self.account;
        }
        
        return adding;
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    add_trans()
                }) {
                    Label("Add", systemImage: "plus")
                }
                Button(action: {
                    remove_trans()
                }) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }.disabled(selected == nil)
                Button(action: {
                    compile_quick()
                }) {
                    Label("Validate", systemImage: "slider.horizontal.2.square")
                }
            }.padding(5)
            HStack {
                Text("For Account:")
                TextField("Enter Account Name", text: $account);
            }.padding([.leading, .trailing], 10)
            Table($adding, selection: $selected) {
                TableColumn("Memo") { $item in
                    TextField("Memo", text: $item.memo)
                }
                TableColumn("Credit") { $item in
                    TextField("Credit", value: $item.credit, format: .currency(code: "USD"))
                }
                TableColumn("Debit") { $item in
                    TextField("Debit", value: $item.debit, format: .currency(code: "USD"))
                }
                TableColumn("Date") { $item in
                    DatePicker("Date", selection: $item.t_date, displayedComponents: .date).labelsHidden()
                }
                TableColumn("Location") { $item in
                    TextField("Location", text: $item.location)
                }
                TableColumn("Category") { $item in
                    TextField("Category", text: $item.category)
                }
                TableColumn("Sub Category") { $item in
                    TextField("Sub Category", text: $item.sub_category)
                }
                TableColumn("Sub Tender") { $item in
                    TextField("Sub Tender", text: $item.sub_tender)
                }
            }.padding(5)
        }.alert("Notice", isPresented: $show_alert) {
            Button("Ok", action: {})
        } message: {
            switch alert_state {
            case .success(let x):
                Text("\(x) Transaction(s) added successfully")
            case .failed(let reason):
                Text("Transaction failed because '\(reason)'")
            }
        }
    }
}

#Preview {
    ManualTransactions()
}

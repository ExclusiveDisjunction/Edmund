//
//  BillOutput.swift
//  Edmund
//
//  Created by Hollan on 4/22/25.
//

import SwiftUI;
import EdmundCore
import SwiftData

private func billPredicate(now: Date) -> Predicate<Bill> {
    let distantFuture = Date.distantPast;
    return #Predicate<Bill> { bill in
        (bill.endDate ?? distantFuture) < now
    }
}
private func utilityPredicate(now: Date) -> Predicate<Utility> {
    let distantFuture = Date.distantPast;
    return #Predicate<Utility> { bill in
        (bill.endDate ?? distantFuture) < now
    }
}

@MainActor
func saveUpcomingBills(context: ModelContext) async {
    let container = Containers.personalContainer;
    
    let calendar = Calendar.current;
    let now = Date.now
    var acc = now;
    var dates: [Date] = [now];
    for _ in 0..<10 {
        guard let new = calendar.date(byAdding: .day, value: 1, to: acc) else {
            print("Unable to get the next date.");
            return;
        }
        
        dates.append(new);
        acc = new;
    }
    
    let context = container.mainContext;
    
    var all: [ UpcomingBillsSnapshot ] = [];
    
    for date in dates{
        let billDescriptor = FetchDescriptor<Bill>();
        let utilityDescriptor = FetchDescriptor<Utility>();
        
        guard let bills: [any BillBase] = try? context.fetch(billDescriptor),
              let utilities: [any BillBase] = try? context.fetch(utilityDescriptor) else {
            print("Unable to get the upcoming bills for \(date)")
            return;
        }
        
        let combined = (bills + utilities).filter { !$0.isExpired && $0.nextBillDate != nil }.sorted(by: { $0.nextBillDate! < $1.nextBillDate! } ).prefix(12);
        let wrapped: [UpcomingBill] = combined.map { UpcomingBill(from: $0)! };
        
        print("for date \(date), \(wrapped.count) upcoming bills are saved.")
        all.append(.init(date: date, bills: wrapped));
    }
    
    
    let fileURL = FileManager
        .default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.exdisj.Edmund.BillTracker")?
        .appendingPathComponent("upcomingBills.json");
    
    guard let fileURL = fileURL else {
        print("Unable to get the upcoming bills path.");
        return;
    }
    
    do {
        let data = try JSONEncoder().encode(all);
        try data.write(to: fileURL);
        print("The next 10 days worth of upcoming bills is saved")
    } catch {
        print("Unable to save upcoming bills \(error)")
    }
}

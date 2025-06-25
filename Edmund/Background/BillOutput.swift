//
//  BillOutput.swift
//  Edmund
//
//  Created by Hollan on 4/22/25.
//

import SwiftUI;
import SwiftData

import WidgetKit
#if os(iOS)
import BackgroundTasks
#endif

@MainActor
func getUpcomingBills(for date: Date, context: ModelContext, billDesc: FetchDescriptor<Bill> = .init(), utilityDesc: FetchDescriptor<Utility> = .init()) async -> UpcomingBillsBundle? {
    guard let bills: [any BillBase] = try? context.fetch(billDesc),
          let utilities: [any BillBase] = try? context.fetch(utilityDesc) else {
        print("Unable to get the upcoming bills for \(date)")
        return nil;
    }
    
    let combined = ( bills + utilities );
    var filtered: [ (any BillBase, Date ) ] = [];
    for item in combined {
        guard !item.isExpired else { continue }
        guard let nextDate = item.nextBillDate(from: date) else { continue }
        
        if nextDate >= date {
            filtered.append(
                (
                    item,
                    nextDate
                )
            )
        }
    }
    
    filtered.sort(using: KeyPathComparator(\.1, order: .forward) )
    let wrapped: [UpcomingBill] = filtered.map { UpcomingBill(name: $0.0.name, amount: $0.0.amount, dueDate: $0.1) };
    
    return .init(date: date, bills: wrapped)
}

@MainActor
func getUpcomingBills() async -> [ UpcomingBillsBundle ]? {
    let container = Containers.container
    
    let calendar = Calendar.current;
    let now = Date.now
    var acc = now;
    var dates: [Date] = [now];
    for _ in 0..<10 {
        guard let new = calendar.date(byAdding: .day, value: 1, to: acc) else {
            print("Unable to get the next date.");
            return nil;
        }
        
        dates.append(new);
        acc = new;
    }
    
    let context = container.mainContext;
    let billDescriptor = FetchDescriptor<Bill>();
    let utilityDescriptor = FetchDescriptor<Utility>();
    
    var all: [ UpcomingBillsBundle ] = [];
    
    for date in dates{
        guard let result = await getUpcomingBills(for: date, context: context, billDesc: billDescriptor, utilityDesc: utilityDescriptor) else {
            return nil;
        }
    
        all.append(result);
    }
    
    return all;
}

func saveUpcomingBills(all: [UpcomingBillsBundle]) async {
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
    } catch {
        print("Unable to save upcoming bills \(error)")
    }
}

func storeWidgetData() async -> Bool{
    guard let all = await getUpcomingBills() else {
        print("Unable to determine the upcoming bills");
        return false;
    }
    await saveUpcomingBills(all: all)
    
    WidgetCenter.shared.reloadAllTimelines()
    return true;
}

#if os(iOS)
func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.exdisj.edmund.refresh",
        using: nil) { task in
            handleAppRefresh(task: task)
        }
}

func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.exdisj.edmund.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 24 * 60) //10 days from now
    
    do {
        try BGTaskScheduler.shared.submit(request)
        print("Background task scheduled")
    } catch {
        print("The background task could not be made \(error)")
    }
}
func handleAppRefresh(task: BGTask) {
    scheduleAppRefresh()
    
    task.expirationHandler = {
        print("App refresh canceled.")
    }
    
    Task {
        let result = await storeWidgetData()

        task.setTaskCompleted(success: result)
    }
}
#else
func refreshWidget() {
    Task {
        await storeWidgetData()
    }
}
#endif

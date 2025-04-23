//
//  BillOutput.swift
//  Edmund
//
//  Created by Hollan on 4/22/25.
//

import SwiftUI;
import EdmundCore
import SwiftData

import WidgetKit
#if os(iOS)
import BackgroundTasks
#endif

@MainActor
func getUpcomingBills() async -> [ UpcomingBillsSnapshot ]? {
#if DEBUG
    let container = Containers.debugContainer
#else
    let container = Containers.personalContainer;
#endif
    
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
    
    var all: [ UpcomingBillsSnapshot ] = [];
    
    for date in dates{
        let billDescriptor = FetchDescriptor<Bill>();
        let utilityDescriptor = FetchDescriptor<Utility>();
        
        guard let bills: [any BillBase] = try? context.fetch(billDescriptor),
              let utilities: [any BillBase] = try? context.fetch(utilityDescriptor) else {
            print("Unable to get the upcoming bills for \(date)")
            return nil;
        }
        
        let combined = (bills + utilities).filter { !$0.isExpired && $0.nextBillDate(from: date) != nil && $0.nextBillDate(from: date)! >= date }.sorted(by: { $0.nextBillDate(from: date)! < $1.nextBillDate(from: date)! } ).prefix(15);
        let wrapped: [UpcomingBill] = combined.map { UpcomingBill(from: $0)! };
        
        print("for date \(date), \(wrapped.count) upcoming bills are saved.")
        all.append(.init(date: date, bills: wrapped));
    }
    
    return all;
}

func saveUpcomingBills(all: [UpcomingBillsSnapshot]) async {
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
        guard let all = await getUpcomingBills() else {
            print("Unable to determine the upcoming bills");
            return;
            task.setTaskCompleted(success: false)
        }
        await saveUpcomingBills(all: all)
        
        WidgetCenter.shared.reloadAllTimelines()
        print("Completed saving to upcoming bills");
        
        task.setTaskCompleted(success: true)
    }
}
#else
func refreshWidget() {
    Task {
        guard let all = await getUpcomingBills() else {
            print("Unable to determine the upcoming bills");
            return;
        }
        await saveUpcomingBills(all: all)
        
        print("Completed saving to upcoming bills");
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#endif

//
//  BillsDateManager.swift
//  Edmund
//
//  Created by Hollan Sellars on 2/14/26.
//

import Edmund
import CoreData
import Testing

struct BillsDueDateManagerTester {
    @MainActor
    init() async throws {
        self.manager = .init(calendar: .current, log: LoggerSystem());
        await manager.reset();
        
        let cx = DataStack.shared.currentContainer.viewContext;
        
        let calendar = Calendar.current;
        let strippedDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: .now)!;
        self.dueDate = calendar.date(byAdding: .day, value: 1, to: strippedDate)!;
        let startDate = calendar.date(byAdding: .month, value: -1, to: dueDate)!;
        
        self.bill = Bill(context: cx);
        bill.name = "Testing Bill";
        bill.startDate = startDate;
        bill.period = .monthly;
        bill.company = "Test";
        bill.kind = .bill;
        
        try cx.save();
    }
    
    let manager: BillsDateManager;
    @MainActor
    let bill: Bill;
    let dueDate: Date;
    
    @Test
    func testDidReset() async throws {
        try await Task.sleep(for: .seconds(1));
        try #require( await manager.isLoaded );
        
        let dueDateInfo = await Task { @MainActor in
            return await manager.fetchAgainstGuarded(id: bill.objectID);
        }.value;
        
        let day: Date? = if case .dueOn(let day) = dueDateInfo { day } else { nil };
        
        #expect( day == dueDate )
    }
}

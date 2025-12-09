//
//  Bill.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI

extension Bill : NamedElement {
    public var name: String {
        get { self.internalName ?? "" }
        set { self.internalName = newValue }
    }
    public var company: String {
        get { self.internalCompany ?? "" }
        set { self.internalCompany = newValue }
    }
    
    public var kind: BillsKind {
        get { BillsKind(rawValue: self.internalKind) ?? .bill }
        set { self.internalKind = newValue.rawValue }
    }
    public var period: TimePeriods {
        get { TimePeriods(rawValue: self.internalPeriod) ?? .monthly }
        set { self.internalPeriod = newValue.rawValue}
    }
    
    /// Returns the price per some other time period.
    func pricePer(_ period: TimePeriods) -> Decimal {
        self.amount * self.period.conversionFactor(period)
    }
    public var avgAmount: Decimal {
        get {
            var total = Decimal();
            var count = 0;
            for datapoint in self.history {
                if let amount = datapoint.amount {
                    total += amount;
                    count += 1;
                }
            }
            
            if count == 0 {
                return Decimal()
            }
            else {
                return total / Decimal(count)
            }
        }
    }
    public var amount: Decimal {
        get {
            self.kind == .utility ? self.avgAmount : (self.internalAmount as Decimal?) ?? Decimal()
        }
        set {
            self.internalAmount = newValue as NSDecimalNumber
        }
    }
    
    public var history: [BillDatapoint] {
        get {
            guard let rawHistory = self.internalHistory, let history = rawHistory as? Set<BillDatapoint> else {
                return Array()
            }
            
            return Array(history);
        }
        set {
            self.internalHistory = Set(newValue) as NSSet
        }
    }
    
    public var startDate: Date {
        get { self.internalStartDate ?? .distantPast }
        set { self.internalStartDate = newValue }
    }
    func computeNextDueDate(relativeTo: Date = .now) -> Date? {
        var walker = TimePeriodWalker(start: self.startDate, end: self.endDate, period: self.period, calendar: .current)
        return walker.walkToDate(relativeTo: relativeTo)
    }
    /// When true, the `endDate` exists, and it is in the past.
    var isExpired: Bool {
        if let endDate = endDate {
            Date.now > endDate
        }
        else {
            false
        }
    }
    public var nextDueDate: Date? {
        var hasher = Hasher()
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
        let computedHash = Int32(hasher.finalize())
        let lastHash = self.oldHash
        
        oldHash = computedHash
        
        if let nextDueDate = internalNextDueDate, computedHash == lastHash {
            return nextDueDate
        }
        else {
            let result = self.computeNextDueDate()
            internalNextDueDate = result;
            return result;
        }
    }
    
    func addPoint(amount: Decimal?) {
        let history = self.history;
        let max = (history.map { $0.id }.max() ?? 0) + 1;
        
        let new = BillDatapoint(context: self.managedObjectContext!)
        new.id = max;
        new.amount = amount;
        new.bill = self;
    }
}

/*
extension Bill {
    public func update(_ from: BillSnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        let name = from.name.trimmingCharacters(in: .whitespaces)
        let company = from.company.trimmingCharacters(in: .whitespaces)
        let location = from.locationNil?.trimmingCharacters(in: .whitespaces)
        let id = BillID(name: name, company: company, location: location)
        
        if id != self.uID {
            guard await unique.swapId(key: .init(Bill.self), oldId: self.uID, newId: id) else {
                throw UniqueFailureError(value: id)
            }
        }
        
        self.name = name
        self.company = company
        self.location = location
        self.startDate = from.startDate
        self.endDate = from.endDateNil
        self.period = from.period
        self.autoPay = from.autoPay
        self.amount = from.amount.rawValue;
        self.kind = from.kind;
        
        let oldPoints = self.history;
        let newPoints = from.history;
        
        // The point here is to use as many old instances as possible, while integrating the changes from the incoming elements.
        // The order is taken from the snapshot, so the same amounts in order will be placed back into the utility.
        
        if newPoints.count == oldPoints.count {
            Self.updateLists(oldList: oldPoints, newList: newPoints)
        }
        else if newPoints.count > oldPoints.count {
            //First, update the elements in the first array, and then create new elements. Join the two lists after adding the newly created.
            let matchedPoints = newPoints[0..<oldPoints.count];
            Self.updateLists(oldList: oldPoints, newList: matchedPoints)
            
            let newInstances = newPoints[oldPoints.count...].enumerated().map { Self.Datapoint($0.element.amount.rawValue, index: $0.offset + oldPoints.count ) };
            
            for instance in newInstances {
                self.modelContext?.insert(instance)
            }
            
            let allPoints = oldPoints + newInstances;
            self.history = allPoints;
        }
        else { //less
            // First grab the instances from the old points that match the count, and then remove the other instances.
            let keeping = Array(oldPoints[..<newPoints.count]); //Being stored back so we need it in array format
            let deleting = oldPoints[newPoints.count...];
            
            Self.updateLists(oldList: keeping, newList: newPoints)
            self.history = keeping;
            
            for delete in deleting {
                self.modelContext?.delete(delete)
            }
        }
        
        self.amount   = from.amount.rawValue
        self.kind = from.kind
    }
}
 */

public extension Bill {
    
    static func examplesExpired(cx: NSManagedObjectContext) {
        let bitwarden = Bill(context: cx);
        bitwarden.name = "Bitwarden Preimum";
        bitwarden.kind = .subscription;
        bitwarden.amount = 9.99;
        bitwarden.company = "Bitwarden";
        bitwarden.startDate = Date.fromParts(2024, 6, 6)!;
        bitwarden.endDate = Date.fromParts(2025, 3, 1);
        bitwarden.period = .anually;
        
        let spotify = Bill(context: cx);
        spotify.name = "Spotify Premium Family";
        spotify.kind = .subscription;
        spotify.company = "Spotify";
        spotify.amount = 16.99;
        spotify.startDate = Date.fromParts(2020, 1, 17)!;
        spotify.endDate = Date.fromParts(2025, 3, 2);
        spotify.period = .monthly;
    }
    static func examplesSubscriptions(cx: NSManagedObjectContext) {
        let appleMusic = Bill(context: cx);
        appleMusic.name = "Apple Music";
        appleMusic.kind = .subscription;
        appleMusic.company = "Apple";
        appleMusic.amount = 5.99;
        appleMusic.startDate = Date.fromParts(2025, 3, 2)!;
        appleMusic.endDate = nil;
        appleMusic.period = .monthly;
        
        let icloud = Bill(context: cx);
        icloud.name = "iCloud+";
        icloud.kind = .subscription;
        icloud.company = "Apple";
        icloud.amount = 2.00;
        icloud.startDate = Date.fromParts(2025, 5, 15)!;
        icloud.endDate = nil;
        icloud.period = .monthly;
        
        let youtube = Bill(context: cx);
        youtube.name = "YouTube Premium";
        youtube.kind = .subscription;
        youtube.company = "YouTube";
        youtube.amount = 9.99;
        youtube.startDate = Date.fromParts(2024, 11, 7)!;
        youtube.endDate = nil;
        youtube.period = .monthly;
    }
    static func examplesBills(cx: NSManagedObjectContext) {
        let studentLoan = Bill(context: cx);
        studentLoan.name = "Student Loan";
        studentLoan.kind = .bill;
        studentLoan.company = "FAFSA";
        studentLoan.amount = 56;
        studentLoan.startDate = Date.fromParts(2025, 3, 2)!;
        studentLoan.endDate = nil;
        studentLoan.period = .monthly;
        
        let carInsurance = Bill(context: cx);
        carInsurance.name = "Car Insurance";
        carInsurance.kind = .bill;
        carInsurance.company = "The General";
        carInsurance.amount = 899;
        carInsurance.startDate = Date.fromParts(2024, 7, 25)!;
        carInsurance.endDate = nil;
        carInsurance.period = .semiAnually;
        
        let internet = Bill(context: cx);
        internet.name = "Internet";
        internet.kind = .bill;
        internet.company = "Spectrum";
        internet.amount = 60;
        internet.startDate = Date.fromParts(2024, 7, 25)!;
        internet.endDate = nil;
        internet.period = .monthly;
    }
    static func examplesUtilities(cx: NSManagedObjectContext) {
        
    }
    
    /// A list of filler data for bills that have already expired.
    static func examples(cx: NSManagedObjectContext) {
        Self.examplesExpired(cx: cx)
        Self.examplesSubscriptions(cx: cx)
        Self.examplesBills(cx: cx)
        Self.examplesUtilities(cx: cx)
    }
}

/*
extension Bill : InspectableElement, EditableElement, TypeTitled {
    public func makeInspectView() -> BillInspect {
        BillInspect(self)
    }
    public static func makeEditView(_ snap: BillSnapshot) -> BillEdit {
        BillEdit(snap)
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Bill",
            plural:   "Bills",
            inspect:  "Inspect Bill",
            edit:     "Edit Bill",
            add:      "Add Bill"
        )
    }
}
 */


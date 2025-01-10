//
//  Payday.swift
//  Edmund
//
//  Created by Hollan on 1/2/25.
//

import SwiftData;
import Foundation;

@Model
public class PayInfo : ObservableObject, Identifiable {
    init(_ amount: Decimal, begin: Date, end: Date? = nil) {
        self.amount = amount;
        self.begin = begin;
        self.end = end;
    }
    
    public var id: UUID = UUID();
    public var amount: Decimal;
    public var begin: Date;
    public var end: Date?;
}

@Model
public class JobInfo : ObservableObject, Identifiable {
    init(_ name: String, pay_info: [PayInfo]) {
        self.name = name;
        self.pay = pay_info;
    }
    
    public var id: UUID = UUID();
    @Attribute(.unique) public var name: String;
    @Relationship(deleteRule: .cascade) public var pay: [PayInfo];
    
    public var current_pay: PayInfo? {
        get {
            if self.pay.isEmpty {
                return nil;
            }
            
            var max: PayInfo? = nil;
            pay.forEach { if $0.end == nil || $0.end! > max?.end ?? Date.distantPast { max = $0 } }
            
            return max;
        }
    }
}

@Model
public class TaxInfo : ObservableObject, Identifiable {
    init(_ percent: Decimal, threshold: Decimal = 0) {
        self.percent = percent;
        self.threshold = threshold;
    }
    
    public var id: UUID = UUID();
    public var percent: Decimal;
    public var threshold: Decimal;
    
    public func apply_on(pay_total: Decimal, tax_total: inout Decimal) {
        if pay_total > threshold {
            tax_total += percent;
        }
    }
}

@Model
public class TaxManifest : ObservableObject, Identifiable {
    init(name: String, taxes: [TaxInfo]) {
        self.name = name;
        self.taxes = taxes;
    }
    
    public var id: UUID = UUID();
    public var name: String;
    @Relationship(deleteRule: .cascade) public var taxes: [TaxInfo];
    
    public func compute_tax_rate(pay_total: Decimal) -> Decimal {
        var result: Decimal = 0.0;
        taxes.forEach{ $0.apply_on(pay_total: pay_total, tax_total: &result) }
        
        return result;
    }
}

@Model
public class PaydayInfo: ObservableObject, Identifiable {
    init(week_num: Int, year: Int, pay_date: Date, job: JobInfo, taxes: TaxManifest, scheduled_hours: Decimal = 0, actual_hours: Decimal = 0, actual_pay: Decimal = 0) {
        self.week_num = week_num
        self.year = year
        self.pay_date = pay_date
        self.taxes = taxes;
        self.job = job
        self.scheduled_hours = scheduled_hours
        self.actual_hours = actual_hours
        self.actual_pay = actual_pay
    }
    
    public var id: UUID = UUID();
    public var week_num: Int;
    public var year: Int;
    public var pay_date: Date;
    @Relationship(deleteRule: .noAction) public var taxes: TaxManifest;
    @Relationship(deleteRule: .noAction) public var job: JobInfo;
    public var scheduled_hours: Decimal;
    public var actual_hours: Decimal;
    public var actual_pay: Decimal;
    
    public var hours_difference: Decimal {
        actual_hours - scheduled_hours
    }
    public var scheduled_pay_est: Decimal {
        let raw_total = scheduled_hours * (job.current_pay?.amount ?? 0);
        let tax_amount = taxes.compute_tax_rate(pay_total: raw_total);
        
        return raw_total * (1 - tax_amount);
    }
    public var actual_pay_est: Decimal {
        let raw_total = actual_hours * (job.current_pay?.amount ?? 0);
        let tax_amount = taxes.compute_tax_rate(pay_total: raw_total);
        
        return raw_total * (1 - tax_amount);
    }
    public var pay_variance: Decimal {
        let est = actual_pay_est;
        return est != 0 ? (est - actual_pay) / (est) : 0
    }
}


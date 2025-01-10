//
//  Paychecks.swift
//  Edmund
//
//  Created by Hollan on 1/2/25.
//

import SwiftUI;
import SwiftData;

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

@Observable
class PaychecksVM {
    
    var job: String = "";
    var taxes: String = "";
    var year: Int = Date.now.get(.year);
}

struct PaychecksView : View {
    @Bindable public var vm: PaychecksVM;
    
    @Query(sort: \PaydayInfo.week_num) private var paydays: [PaydayInfo];
    @Query(sort: \JobInfo.name) private var jobs: [JobInfo];
    @Query(sort: \TaxManifest.name) private var taxes: [TaxManifest];
    
    @State var alert_msg: String = "";
    @State var show_alert: Bool = true;
    @State var alert_is_err: Bool = false;
    
    private func get_paydays() -> [PaydayInfo] {
        var result = paydays.filter { $0.job.name == vm.job && $0.year == vm.year }
        result.sort { $0.week_num < $1.week_num }
        
        return result;
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Paychecks").font(.title)
                Spacer()
            }
            
            Grid {
                GridRow {
                    Text("For Job")
                    Picker("Job", selection: $vm.job) {
                        ForEach(jobs) { item in
                            Text(item.name).tag(item.name)
                        }
                    }.labelsHidden()
                }
                GridRow {
                    Text("Year")
                    TextField("Year", value: $vm.year, format: .number.precision(.fractionLength(0)).grouping(.never))
                }
            }.padding(.bottom)
            
            Table(get_paydays()) {
                TableColumn("Week") { item in
                    Text("\(item.week_num)")
                }
                TableColumn("Pay Date") { item in
                    Text("\(item.pay_date, format: .dateTime.day())")
                }
                TableColumn("For Job") { item in
                    Text(item.job.name)
                }
                TableColumn("Wage") { item in
                    if let curr_job = item.job.current_pay {
                        Text("\(curr_job.amount, format: .currency(code: "USD"))")
                    }
                    else {
                        Text("NA")
                    }
                }
                TableColumn("Scheduled Hours") { item in
                    Text("\(item.scheduled_hours, format: .number.precision(.fractionLength(2))) hr")
                }
                TableColumn("Actual Hours") { item in
                    Text("\(item.actual_hours, format: .number.precision(.fractionLength(2))) hr")
                }
                TableColumn("Difference") { item in
                    Text("\(item.hours_difference, format: .number.precision(.fractionLength(2))) hr")
                }
                TableColumn("Scheduled Pay") { item in
                    Text("\(item.scheduled_pay_est, format: .currency(code: "USD"))")
                }
                TableColumn("Actual Exp. Pay") { item in
                    Text("\(item.actual_pay_est, format: .currency(code: "USD"))")
                }
                TableColumn("Actual Pay") { item in
                    Text("\(item.actual_pay, format: .currency(code: "USD"))")
                }
                /*/
                TableColumn("Variance") { item in
                    Text("\(item.pay_variance, format: .percent)")
                }
                */
            }
        }.padding().alert(alert_is_err ? "Error" : "Notice", isPresented: $show_alert, actions: {
            Button("Ok", action: {
                show_alert = false;
            })
        }, message: {
            Text(alert_msg)
        })
    }
}

#Preview {
    PaychecksView(vm: PaychecksVM())
}

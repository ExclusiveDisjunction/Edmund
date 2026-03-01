//
//  BillCostChart.swift
//  Edmund
//
//  Created by Hollan Sellars on 2/23/26.
//

import SwiftUI
import Charts

public struct BillCostChart<C> : View where C: RandomAccessCollection, C.Element == Bill {
    public init(_ source: SelectionContext<C>) {
        self.source = source;
    }
    
    private let source: SelectionContext<C>;
    @State private var chartData: [Bill]? = nil;
    @State private var total: Decimal = 0.0;
    
    @AppStorage("showcasePeriod") private var showcasePeriod: TimePeriods = .weekly;
    @Environment(\.dismiss) private var dismiss;
    
    private func sortData() -> [Bill] {
        let result = source.data.filter { !$0.isExpired }.sorted(using: KeyPathComparator(\Bill.amount, order: .forward));
        self.total = result.map { $0.pricePer(showcasePeriod) }.reduce(Decimal(), +);
        
        return result;
    }
    
    public var body: some View {
        VStack {
            HStack {
                Text("Cost Breakdown").font(.title2)
                Spacer()
            }
            
            if let data = chartData {
                Chart(data) { bill in
                    let price = bill.pricePer(showcasePeriod)
                    let text = Text(verbatim: bill.name)
                    let mark = SectorMark(
                        angle: .value(
                            text,
                            price
                        )
                    ).foregroundStyle(
                        by: .value(
                            text,
                            price
                        )
                    );
                    
                    if price / total >= 0.1 {
                        mark
                            .annotation(position: .overlay) {
                                text
                            }
                    }
                    else {
                        mark
                    }
                }.frame(minHeight: 350)
            }
            else {
                ProgressView()
            }
            
            HStack {
                Spacer()
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
            .onAppear {
                Task { @MainActor in
                    let data = sortData();
                    withAnimation {
                        self.chartData = data
                    }
                }
            }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<Bill>(sortDescriptors: []) var bills;
    //@Previewable @State var selection: Set<Bill.ID>;
    
    VStack {
        BillCostChart(SelectionContext(data: bills, selection: .constant(Set())))
    }.frame(height: 400)
}

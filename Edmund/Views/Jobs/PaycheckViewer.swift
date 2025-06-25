//
//  PaycheckViewer.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/9/25.
//

import SwiftUI
import SwiftData

struct PaycheckViewer : View {
    @State private var selectedJob: TraditionalJobWrapper?;
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now);
    
    var body: some View {
        VStack {
            HStack {
                Text("Job:")
                if let job = selectedJob {
                    Text(job.data.position)
                }
                else{
                    Text("No job selected")
                        .italic()
                }
                
                Spacer()
                
                Button("...", action: {
                    
                })
            }
            
            HStack {
                Text("Year:")
                TextField("Year", value: $selectedYear, format: .number.precision(.fractionLength(0)).grouping(.never).sign(strategy: .never))
            }
        }.navigationTitle("Paychecks")
            .padding()
            .toolbar {
                
            }
    }
}


#Preview {
    PaycheckViewer()
        .modelContainer(Containers.debugContainer)
}

//
//  BillsFilter.swift
//  Edmund
//
//  Created by Hollan Sellars on 2/28/26.
//

import SwiftUI
import CoreData

@MainActor
@Observable
public class BillsFilterState : Equatable, Hashable {
    public init() {
        self.kinds = Set(BillsKind.allCases);
        self.periods = Set(TimePeriods.allCases);
    }
    
    public var kinds: Set<BillsKind>;
    public var periods: Set<TimePeriods>;
    
    public func makePredicate() -> NSPredicate {
        var compositePredicates: [NSPredicate] = [];
        
        let kindsReduced = self.kinds.map { $0.rawValue };
        compositePredicates.append(
            NSPredicate(format: "internalKind in %@", kindsReduced)
        )
        
        let periodsReduced = self.periods.map { Int16($0.rawValue) };
        compositePredicates.append(
            NSPredicate(format: "internalPeriod in %@", periodsReduced)
        );
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: compositePredicates)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(kinds);
        hasher.combine(periods);
    }
    public static func ==(lhs: BillsFilterState, rhs: BillsFilterState) -> Bool {
        lhs.kinds == rhs.kinds && lhs.periods == rhs.periods
    }
}

public struct FilterSubsection<C, T> : View
where C: AnyObject,
      T: Hashable & Identifiable & Displayable & CaseIterable,
      T.AllCases: RandomAccessCollection {
    
    public init(_ name: LocalizedStringKey, source: C, path: WritableKeyPath<C, Set<T>>) {
        self.name = name;
        self.source = source;
        self.path = path;
    }
    
    let name: LocalizedStringKey;
    let source: C;
    let path: WritableKeyPath<C, Set<T>>;

    func bind(val: T) -> Binding<Bool> {
        Binding(
            get: {
                source[keyPath: path].contains(val)
            },
            set: { [source] newValue in
                var source = source;
                
                if newValue {
                    source[keyPath: path].insert(val)
                }
                else {
                    source[keyPath: path].remove(val)
                }
            }
        )
    }
    
    public var body: some View {
        Section {
            ForEach(T.allCases) { value in
                Toggle(value.display, isOn: bind(val: value))
            }
        } header: {
            HStack {
                Text(name)
                
                Divider()
                
                Button("Select All") { [source] in
                    var source = source;
                    
                    source[keyPath: path] = Set(T.allCases)
                }.buttonStyle(.borderless)
                Button("Deselect All") { [source] in
                    var source = source;
                    
                    source[keyPath: path] = Set()
                }.buttonStyle(.borderless)
            }
        }
    }
}

public struct BillsFilterView : View {
    public init(_ state: BillsFilterState) {
        self.state = state;
    }
    
    @Bindable private var state: BillsFilterState;
    
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            HStack {
                Text("Bill Filters")
                    .font(.title2)
                
                Spacer()
            }
            
            List {
                FilterSubsection("Kind", source: state, path: \.kinds)
                FilterSubsection("Time Periods", source: state, path: \.periods)
            }.frame(minHeight: 200)
            
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

#Preview {
    @Previewable let state = BillsFilterState();
    
    BillsFilterView(state)
}

//
//  SalariedJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import SwiftData

extension SalariedJob {
    @objc public override var grossAmount: Decimal {
        get { (self.internalGrossAmount as Decimal?) ?? Decimal() }
        set { self.internalGrossAmount = newValue as NSDecimalNumber }
    }
}

/*
extension SalariedJob: EditableElement, InspectableElement, TypeTitled {
    public static var typeDisplay: TypeTitleStrings {
        .init(
            singular: "Salaried Job",
            plural: "Salaried Jobs",
            inspect: "Inspect Salaried Job",
            edit: "Edit Salaried Job",
            add: "Add Salaried Job"
        )
    }
    
    public typealias InspectorView = SalariedJobInspector;
    public typealias EditView = SalariedJobEdit;
    
    public func makeInspectView() -> SalariedJobInspector {
        SalariedJobInspector(self)
    }
    public static func makeEditView(_ snap: SalariedJobSnapshot) -> SalariedJobEdit {
        SalariedJobEdit(snap)
    }
}
 */

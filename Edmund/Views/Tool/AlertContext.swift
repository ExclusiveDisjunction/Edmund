//
//  AlertContext.swift
//  Edmund
//
//  Created by Hollan on 1/6/25.
//

import SwiftUI

struct AlertContext {
    init() {
        self.init("", show_alert: false, is_error: true)
    }
    init(_ message: String, show_alert: Bool = true, is_error: Bool = true) {
        self.message = message
        self.show_alert = show_alert
        self.is_error = is_error
    }
    
    @State var message: String
    @State var show_alert: Bool
    @State var is_error: Bool
}

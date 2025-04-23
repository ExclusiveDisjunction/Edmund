//
//  AppIntent.swift
//  Widget-macOS
//
//  Created by Hollan on 4/22/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Upcoming Bills" }
    static var description: IntentDescription { "A quick glance of your upcoming bills, and their amounts" }
}

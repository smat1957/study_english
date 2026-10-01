//
//  EWatchApp.swift
//  EWatch Watch App
//
//  Created by 的池秋成 on 2024/10/31.
//

import SwiftUI

@main
struct EWatch_Watch_AppApp: App {
    @StateObject private var connector = PhoneConnector()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connector)
        }
    }
}

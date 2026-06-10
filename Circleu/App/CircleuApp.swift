//
//  CircleuApp.swift
//  Circleu
//
//  Created by David Oyarekhua on 2/6/2026.
//

import SwiftUI

@main
struct CircleuApp: App {
    init() {
        FirebaseRuntime.configureIfAvailable()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

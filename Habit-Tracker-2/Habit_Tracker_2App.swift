//
//  Habit_Tracker_2App.swift
//  Habit-Tracker-2
//
//  Created by Anirudh Ryali on 1/10/26.
//

import SwiftUI
import SwiftData

@main
struct Habit_Tracker_2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Habit.self)
    }
}

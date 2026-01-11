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
    let container: ModelContainer

    init() {
        let schema = Schema([Habit.self, HabitCompletion.self])
        let storeURL = Self.makeStoreURL()
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let builtContainer: ModelContainer

        do {
            builtContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            #if targetEnvironment(simulator)
            print("SwiftData migration failed on simulator. Clearing store and retrying: \(error)")
            Self.deletePersistentStore(at: storeURL)
            builtContainer = try! ModelContainer(for: schema, configurations: config)
            #else
            fatalError("SwiftData container failed to initialize: \(error)")
            #endif
        }

        container = builtContainer

        // Insert sample data if no habits exist
        insertSampleDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    @MainActor
    private func insertSampleDataIfNeeded() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Habit>()

        guard let count = try? context.fetchCount(descriptor), count == 0 else {
            return
        }

        let calendar = Calendar.current
        let today = Date()

        // Habit started a month ago with scattered completions to show inactive/failed/completed states
        let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        let sampleHabit = Habit(
            name: "Sample Habit",
            icon: "dumbbell",
            color: "#FF6B6B",
            createdAt: oneMonthAgo
        )
        context.insert(sampleHabit)

        // Add completions on scattered days (leaving gaps to show "failed" days)
        let completedDays = [-1, -2, -3, -5, -7, -8, -12, -14, -15, -18, -20, -22, -25, -28]
        for dayOffset in completedDays {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let completion = HabitCompletion(date: calendar.startOfDay(for: date), count: 1)
                completion.habit = sampleHabit
                context.insert(completion)
            }
        }

        // Add two more recent habits for comparison
        let runHabit = Habit(name: "Morning Run", icon: "figure.run", color: "#51CF66")
        context.insert(runHabit)

        let waterHabit = Habit(name: "Drink Water", icon: "drop.fill", color: "#339AF0", completionsPerDay: 8)
        context.insert(waterHabit)
    }

    private static func makeStoreURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        return appSupport.appendingPathComponent("default.store")
    }

    private static func deletePersistentStore(at url: URL) {
        let fileManager = FileManager.default
        let walURL = URL(fileURLWithPath: url.path + "-wal")
        let shmURL = URL(fileURLWithPath: url.path + "-shm")
        let relatedURLs = [url, walURL, shmURL]

        for relatedURL in relatedURLs {
            _ = try? fileManager.removeItem(at: relatedURL)
        }
    }
}

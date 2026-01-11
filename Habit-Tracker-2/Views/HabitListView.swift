//
//  HabitListView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var habitToEdit: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(habits) { habit in
                        HabitCardView(
                            habit: habit,
                            onEdit: { habitToEdit = habit },
                            onDelete: { deleteHabit(habit) }
                        )
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                EditHabitView()
            }
            .sheet(item: $habitToEdit) { habit in
                EditHabitView(habit: habit)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }
}


#Preview("Empty state") {
    HabitListView()
        .modelContainer(PreviewContainer.empty)
}

#Preview("With habits") {
    HabitListView()
        .modelContainer(PreviewContainer.withSampleHabits)
}

@MainActor
struct PreviewContainer {
    static var empty: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Habit.self, configurations: config)
        return container
    }

    static var withSampleHabits: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Habit.self, configurations: config)
        let calendar = Calendar.current
        let today = Date()

        // Habit started a month ago with scattered completions
        let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        let exerciseHabit = Habit(
            name: "Exercise",
            emoji: "💪",
            color: "#FF6B6B",
            createdAt: oneMonthAgo
        )
        container.mainContext.insert(exerciseHabit)

        // Add some completions (not every day to show failed days)
        let completedDays = [-1, -2, -3, -5, -7, -8, -12, -14, -15, -18, -20, -22, -25, -28]
        for dayOffset in completedDays {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let completion = HabitCompletion(date: date, count: 1)
                completion.habit = exerciseHabit
                container.mainContext.insert(completion)
            }
        }

        let habits = [
            Habit(name: "Morning Run", emoji: "🏃", color: "#51CF66"),
            Habit(name: "Drink Water", emoji: "💧", color: "#339AF0", completionsPerDay: 8),
        ]
        habits.forEach { container.mainContext.insert($0) }

        return container
    }
}

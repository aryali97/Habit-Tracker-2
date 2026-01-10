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

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(habits) { habit in
                        HabitCardView(habit: habit)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteHabit(habit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
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
                AddHabitPlaceholderView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }
}

// Placeholder until Phase 3
struct AddHabitPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add Habit")
                    .font(.title)

                Text("Full edit view coming in Phase 3")
                    .foregroundStyle(.secondary)

                Button("Add Sample Habit") {
                    let habit = Habit(
                        name: "Sample Habit",
                        emoji: ["🏃", "💪", "📚", "💧", "🧘"].randomElement()!,
                        color: HabitColors.palette.randomElement()!
                    )
                    modelContext.insert(habit)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
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

        let habits = [
            Habit(name: "Morning Run", emoji: "🏃", color: "#51CF66"),
            Habit(name: "Read Books", emoji: "📚", color: "#BE4BDB"),
            Habit(name: "Drink Water", emoji: "💧", color: "#339AF0", completionsPerDay: 8),
        ]
        habits.forEach { container.mainContext.insert($0) }

        return container
    }
}

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

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale.current
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: Date()).uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.headerSecondary)

                        Text("Habits")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button {
                        Haptics.impact(.light)
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.addButtonForeground)
                            .frame(width: 36, height: 36)
                            .background(AppColors.addButtonBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 16)

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
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
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
        Haptics.impact(.rigid)
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
            icon: "dumbbell",
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
            Habit(name: "Morning Run", icon: "figure.run", color: "#51CF66"),
            Habit(name: "Drink Water", icon: "drop.fill", color: "#339AF0", completionsPerDay: 8),
        ]
        habits.forEach { container.mainContext.insert($0) }

        return container
    }
}

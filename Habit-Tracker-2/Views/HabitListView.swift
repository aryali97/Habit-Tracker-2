//
//  HabitListView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.habitStartDate) private var habits: [Habit]
    @Query(sort: \HabitOrder.orderIndex) private var habitOrders: [HabitOrder]
    @State private var showingAddHabit = false
    @State private var habitToEdit: Habit?
    @State private var showingReorder = false

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
                        ForEach(orderedHabits) { habit in
                            HabitCardView(
                                habit: habit,
                                onEdit: { habitToEdit = habit },
                                onDelete: { deleteHabit(habit) },
                                onReorder: { showingReorder = true }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .animation(.snappy, value: orderedHabits.map(\.id))
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
            .sheet(isPresented: $showingReorder) {
                ReorderHabitsSheet(habits: orderedHabits)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { ensureHabitOrder() }
        .onChange(of: habits.count) { _, _ in
            ensureHabitOrder()
        }
    }

    private func deleteHabit(_ habit: Habit) {
        Haptics.impact(.rigid)
        withAnimation(.snappy) {
            if let order = habitOrders.first(where: { $0.habit.id == habit.id }) {
                modelContext.delete(order)
            }
            modelContext.delete(habit)
        }
    }

    private var orderedHabits: [Habit] {
        let orderLookup = Dictionary(uniqueKeysWithValues: habitOrders.map { ($0.habit.id, $0.orderIndex) })
        return habits.sorted {
            let leftOrder = orderLookup[$0.id] ?? Int.max
            let rightOrder = orderLookup[$1.id] ?? Int.max
            if leftOrder != rightOrder {
                return leftOrder < rightOrder
            }
            return $0.habitStartDate < $1.habitStartDate
        }
    }

    private func ensureHabitOrder() {
        guard !habits.isEmpty else { return }

        let orderById = Dictionary(uniqueKeysWithValues: habitOrders.map { ($0.habit.id, $0) })
        let sortedHabits = habits.sorted {
            let leftOrder = orderById[$0.id]?.orderIndex ?? Int.max
            let rightOrder = orderById[$1.id]?.orderIndex ?? Int.max
            if leftOrder != rightOrder {
                return leftOrder < rightOrder
            }
            return $0.habitStartDate < $1.habitStartDate
        }

        var nextIndex = 0
        for habit in sortedHabits {
            if let order = orderById[habit.id] {
                order.orderIndex = nextIndex
            } else {
                let order = HabitOrder(habit: habit, orderIndex: nextIndex)
                modelContext.insert(order)
            }
            nextIndex += 1
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save habit order: \(error)")
        }
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
        let container = try! ModelContainer(
            for: Habit.self,
            HabitCompletion.self,
            HabitOrder.self,
            configurations: config
        )
        return container
    }

    static var withSampleHabits: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Habit.self,
            HabitCompletion.self,
            HabitOrder.self,
            configurations: config
        )
        let calendar = Calendar.current
        let today = Date()

        // Habit started a month ago with scattered completions
        let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        let exerciseHabit = Habit(
            name: "Exercise",
            icon: "dumbbell",
            color: "#FF6B6B",
            habitStartDate: oneMonthAgo
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

        let allHabits = [exerciseHabit] + habits
        for (index, habit) in allHabits.enumerated() {
            let order = HabitOrder(habit: habit, orderIndex: index)
            container.mainContext.insert(order)
        }

        return container
    }
}

//
//  ReorderHabitsSheet.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData
import UIKit

struct ReorderHabitsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitOrder.orderIndex) private var habitOrders: [HabitOrder]
    @State private var orderedHabits: [Habit]

    init(habits: [Habit]) {
        _orderedHabits = State(initialValue: habits)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(orderedHabits) { habit in
                    HabitReorderRow(habit: habit)
                        .listRowBackground(AppColors.cardBackground)
                }
                .onMove(perform: moveHabits)
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Reorder Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.visible)
    }

    private func moveHabits(from source: IndexSet, to destination: Int) {
        orderedHabits.move(fromOffsets: source, toOffset: destination)
        persistOrder()
    }

    private func persistOrder() {
        let orderById = Dictionary(uniqueKeysWithValues: habitOrders.map { ($0.habit.id, $0) })
        for (index, habit) in orderedHabits.enumerated() {
            if let order = orderById[habit.id] {
                order.orderIndex = index
            } else {
                let order = HabitOrder(habit: habit, orderIndex: index)
                modelContext.insert(order)
            }
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to persist habit order: \(error)")
        }
    }

    private var detentHeight: CGFloat {
        let rowHeight: CGFloat = 56
        let topPadding: CGFloat = 120
        let maxHeight = (currentScreenHeight ?? 800) * 0.75
        let calculated = topPadding + (rowHeight * CGFloat(orderedHabits.count))
        return min(maxHeight, max(calculated, 240))
    }

    private var currentScreenHeight: CGFloat? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
            .bounds
            .height
    }
}

private struct HabitReorderRow: View {
    let habit: Habit

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(habitColor)
                .frame(width: 38, height: 38)
                .background(habitColor.opacity(HabitOpacity.inactive))
                .clipShape(Circle())

            Text(habit.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

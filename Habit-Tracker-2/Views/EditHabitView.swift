//
//  EditHabitView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Existing habit for editing (nil for new habit)
    let habitToEdit: Habit?

    // Form state
    @State private var emoji: String = "⭐️"
    @State private var name: String = ""
    @State private var habitDescription: String = ""
    @State private var selectedColor: String = HabitColors.default
    @State private var completionsPerDay: Int = 1
    @State private var streakGoalValue: Int = 1
    @State private var streakGoalPeriod: StreakPeriod = .day
    @State private var streakGoalType: StreakGoalType = .dayBasis

    // Emoji picker state
    @State private var showEmojiPicker = false
    @FocusState private var isEmojiFieldFocused: Bool

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isEditing: Bool {
        habitToEdit != nil
    }

    init(habit: Habit? = nil) {
        self.habitToEdit = habit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Emoji Picker
                    EmojiPickerButton(emoji: $emoji)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Habit name", text: $name)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Optional description", text: $habitDescription)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Color Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ColorPickerGrid(selectedColor: $selectedColor)
                    }

                    // Completions Per Day
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completions Per Day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(completionsPerDay)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 40)

                            Text("/ Day")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Stepper("", value: $completionsPerDay, in: 1...100)
                                .labelsHidden()
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("The square will be filled completely when this number is met")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Streak Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak Goal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(streakGoalValue)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 40)

                            Text("/")
                                .foregroundStyle(.secondary)

                            Picker("Period", selection: $streakGoalPeriod) {
                                Text("Day").tag(StreakPeriod.day)
                                Text("Week").tag(StreakPeriod.week)
                            }
                            .pickerStyle(.menu)
                            .tint(.white)

                            Spacer()

                            Stepper("", value: $streakGoalValue, in: 1...365)
                                .labelsHidden()
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Goal Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Type")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Goal Type", selection: $streakGoalType) {
                            Text("Day Basis").tag(StreakGoalType.dayBasis)
                            Text("Value Basis").tag(StreakGoalType.valueBasis)
                        }
                        .pickerStyle(.segmented)

                        Text(streakGoalType == .dayBasis
                            ? "Complete on \(streakGoalValue) \(streakGoalPeriod == .day ? "consecutive days" : "days this week")"
                            : "Reach \(streakGoalValue) total completions this \(streakGoalPeriod.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: saveHabit) {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isFormValid
                                ? Color(hex: selectedColor)
                                : Color.gray.opacity(0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isFormValid)
                .padding()
                .background(AppColors.background)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadExistingHabit()
        }
    }

    private func loadExistingHabit() {
        guard let habit = habitToEdit else { return }
        emoji = habit.emoji
        name = habit.name
        habitDescription = habit.habitDescription ?? ""
        selectedColor = habit.color
        completionsPerDay = habit.completionsPerDay
        streakGoalValue = habit.streakGoalValue
        streakGoalPeriod = habit.streakGoalPeriod
        streakGoalType = habit.streakGoalType
    }

    private func saveHabit() {
        if let habit = habitToEdit {
            // Update existing habit
            habit.emoji = emoji
            habit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            habit.habitDescription = habitDescription.isEmpty ? nil : habitDescription
            habit.color = selectedColor
            habit.completionsPerDay = completionsPerDay
            habit.streakGoalValue = streakGoalValue
            habit.streakGoalPeriod = streakGoalPeriod
            habit.streakGoalType = streakGoalType
        } else {
            // Create new habit
            let habit = Habit(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                habitDescription: habitDescription.isEmpty ? nil : habitDescription,
                emoji: emoji,
                color: selectedColor,
                completionsPerDay: completionsPerDay,
                streakGoalValue: streakGoalValue,
                streakGoalPeriod: streakGoalPeriod,
                streakGoalType: streakGoalType
            )
            modelContext.insert(habit)
        }

        dismiss()
    }
}

// MARK: - Emoji Picker Button

struct EmojiPickerButton: View {
    @Binding var emoji: String
    @State private var emojiInput: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field for emoji keyboard
            TextField("", text: $emojiInput)
                .keyboardType(.default)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
                .onChange(of: emojiInput) { oldValue, newValue in
                    // Extract only emoji characters
                    let emojis = newValue.filter { $0.isEmoji }
                    if let lastEmoji = emojis.last {
                        emoji = String(lastEmoji)
                        emojiInput = ""
                        isFocused = false
                    }
                }

            // Visible button
            Button {
                isFocused = true
            } label: {
                Text(emoji)
                    .font(.system(size: 48))
                    .frame(width: 88, height: 88)
                    .background(AppColors.cardBackground)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Color Picker Grid

struct ColorPickerGrid: View {
    @Binding var selectedColor: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HabitColors.palette, id: \.self) { colorHex in
                ColorCircle(
                    colorHex: colorHex,
                    isSelected: selectedColor == colorHex
                )
                .onTapGesture {
                    selectedColor = colorHex
                }
            }
        }
    }
}

struct ColorCircle: View {
    let colorHex: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: colorHex))
                .aspectRatio(1, contentMode: .fit)

            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white, lineWidth: 3)
            }
        }
    }
}

// MARK: - Character Extension

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

// MARK: - Previews

#Preview("New Habit") {
    EditHabitView()
        .modelContainer(PreviewContainer.empty)
}

#Preview("Edit Habit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)
    let habit = Habit(
        name: "Morning Run",
        habitDescription: "Run every morning",
        emoji: "🏃",
        color: "#51CF66",
        completionsPerDay: 1,
        streakGoalValue: 5,
        streakGoalPeriod: .week,
        streakGoalType: .dayBasis
    )
    container.mainContext.insert(habit)

    return EditHabitView(habit: habit)
        .modelContainer(container)
}

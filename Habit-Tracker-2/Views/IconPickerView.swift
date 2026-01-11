//
//  IconPickerView.swift
//  Habit-Tracker-2
//

import SwiftUI

struct IconCategory: Identifiable {
    let id = UUID()
    let name: String
    let icons: [String]
}

struct HabitIcons {
    static let categories: [IconCategory] = [
        IconCategory(name: "Activities", icons: [
            "alarm", "bell", "calendar", "clock", "timer",
            "cup.and.saucer", "mug", "fork.knife", "cart",
            "bag", "creditcard", "wallet.pass",
            "book", "book.closed", "bookmark", "newspaper",
            "pencil", "highlighter", "paintbrush", "scissors",
            "folder", "tray", "archivebox", "doc.text",
            "keyboard", "desktopcomputer", "laptopcomputer", "iphone",
            "headphones", "tv", "gamecontroller", "pianokeys"
        ]),
        IconCategory(name: "Health & Fitness", icons: [
            "figure.run", "figure.walk", "figure.hiking",
            "figure.pool.swim", "figure.outdoor.cycle", "figure.yoga",
            "figure.strengthtraining.traditional", "figure.cooldown",
            "figure.dance", "figure.skiing.downhill", "figure.climbing",
            "dumbbell", "sportscourt", "tennis.racket", "basketball",
            "football", "volleyball", "soccerball",
            "heart", "heart.fill", "bolt.heart", "waveform.path.ecg",
            "cross.case", "pills", "bandage", "stethoscope",
            "bed.double", "moon.zzz", "zzz", "lungs"
        ]),
        IconCategory(name: "Food & Drink", icons: [
            "cup.and.saucer.fill", "mug.fill", "takeoutbag.and.cup.and.straw",
            "waterbottle", "drop", "drop.fill",
            "carrot", "leaf", "tree",
            "flame", "birthday.cake", "popcorn"
        ]),
        IconCategory(name: "Education", icons: [
            "graduationcap", "book.pages", "text.book.closed",
            "studentdesk", "backpack", "pencil.and.ruler",
            "globe", "map", "building.columns",
            "brain", "lightbulb", "questionmark.circle",
            "a.magnify", "character.book.closed", "textformat.abc"
        ]),
        IconCategory(name: "Work & Productivity", icons: [
            "briefcase", "building.2", "building",
            "chart.bar", "chart.line.uptrend.xyaxis", "chart.pie",
            "list.bullet", "checklist", "list.clipboard",
            "calendar.badge.clock", "clock.badge.checkmark",
            "target", "flag", "flag.checkered",
            "gearshape", "wrench.and.screwdriver", "hammer"
        ]),
        IconCategory(name: "Communication", icons: [
            "message", "bubble.left", "phone",
            "envelope", "paperplane", "megaphone",
            "person", "person.2", "person.3",
            "hand.raised", "hand.thumbsup", "hand.wave",
            "face.smiling", "star", "heart.circle"
        ]),
        IconCategory(name: "Nature", icons: [
            "sun.max", "moon", "cloud",
            "cloud.rain", "snowflake", "wind",
            "leaf.fill", "tree.fill", "mountain.2",
            "water.waves", "flame.fill", "sparkles",
            "pawprint", "bird", "fish",
            "ant", "ladybug", "tortoise"
        ]),
        IconCategory(name: "Travel", icons: [
            "car", "bus", "tram",
            "airplane", "ferry", "bicycle",
            "figure.walk.motion", "map.fill", "mappin.and.ellipse",
            "suitcase", "beach.umbrella", "camera",
            "binoculars", "tent", "mountain.2.fill"
        ]),
        IconCategory(name: "Entertainment", icons: [
            "music.note", "music.mic", "guitars",
            "film", "video", "play.rectangle",
            "photo", "paintpalette", "theatermasks",
            "party.popper", "balloon", "gift",
            "dice", "puzzlepiece", "arcade.stick"
        ]),
        IconCategory(name: "Home", icons: [
            "house", "house.fill", "sofa",
            "bed.double.fill", "shower", "bathtub",
            "washer", "refrigerator", "oven",
            "lightbulb.max", "fan", "thermometer",
            "lock", "key", "door.left.hand.open"
        ]),
        IconCategory(name: "Finance", icons: [
            "dollarsign.circle", "banknote", "creditcard.fill",
            "chart.line.uptrend.xyaxis", "percent", "plusminus",
            "building.columns.fill", "safe", "bitcoinsign.circle"
        ]),
        IconCategory(name: "Spiritual", icons: [
            "hands.sparkles", "sparkle", "moon.stars",
            "sun.horizon", "rays", "wand.and.stars",
            "leaf.circle", "figure.mind.and.body", "infinity"
        ])
    ]

    static let defaultIcon = "star.fill"

    static var allIcons: [String] {
        categories.flatMap { $0.icons }
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var filteredCategories: [IconCategory] {
        if searchText.isEmpty {
            return HabitIcons.categories
        }

        let searchLower = searchText.lowercased()
        return HabitIcons.categories.compactMap { category in
            let matchingIcons = category.icons.filter { icon in
                icon.lowercased().contains(searchLower) ||
                category.name.lowercased().contains(searchLower)
            }
            if matchingIcons.isEmpty {
                return nil
            }
            return IconCategory(name: category.name, icons: matchingIcons)
        }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(filteredCategories) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.name)
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(category.icons, id: \.self) { icon in
                                    IconCell(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        onTap: {
                                            Haptics.selection()
                                            selectedIcon = icon
                                            dismiss()
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .searchable(text: $searchText, prompt: "Search icons")
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct IconCell: View {
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white, lineWidth: 2)
                    }
                }
        }
        .scaleEffect(isSelected ? 1.06 : 1)
        .shadow(color: isSelected ? Color.white.opacity(0.25) : .clear, radius: 8, x: 0, y: 5)
        .animation(.snappy, value: isSelected)
        .buttonStyle(PressScaleButtonStyle())
    }
}

#Preview {
    IconPickerView(selectedIcon: .constant("star.fill"))
}

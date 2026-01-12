# Habit Tracker App

iOS 26+ habit tracking app with streak visualization and customizable goals.

## Tech Stack

- **Platform**: iOS 26+ only
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData (local only, no CloudKit)
- **Architecture**: MVVM with SwiftUI's @Observable macro

## Build & Verification

**IMPORTANT**: Always use XcodeBuildMCP tools for building and testing. Never use direct xcodebuild bash commands.

- Use `session-set-defaults` to configure: scheme, simulator (iPhone 15 Pro)
- Use `build_sim` to build for simulator
- Use `build_run_sim` to build and run on simulator
- Use `test_sim` to run tests
- Use `screenshot` to capture simulator screenshots for verification
- Use `describe_ui` to inspect UI hierarchy
- Verification must include relevant UI automation via XcodeBuildMCP (tap, scroll, type, etc.), not just build + screenshot
- If UI state looks stale, clean the build and reboot/erase the simulator before re-verifying
- Prefer installing the app from `./DerivedData/Build/Products/Debug-iphonesimulator/Habit-Tracker-2.app` to avoid stale builds from the default DerivedData path
- If simulator visuals don’t match device, reinstall using the `./DerivedData` app path and re-run UI automation before concluding
- For verification runs, always `clean` then `build_sim` with `derivedDataPath ./DerivedData`, then reinstall from the `./DerivedData` app path to ensure a fresh build is being exercised

## Product Overview

### Habit Configuration
Each habit supports:
- **Icon**: SF Symbols selection
- **Name**: Required text
- **Description**: Optional text
- **Color**: Selected from a preset palette
- **Completions per day**: 1 for once-daily habits, or higher for multi-completion habits
- **Goal**: Configurable target with:
  - **Period**: Day / Week / Month
  - **Value**: Target number
  - **Type**: Day basis or Value basis
    - Day basis: "Complete on X days this period"
    - Value basis: "Reach X total completions this period"

### Main View (Habit List)
- Scrollable list of habit cards
- Add habit button (+) in navigation bar
- Each card shows:
  - Icon (left side, with habit color background)
  - Habit name
  - Completion button (right side)
  - Grid visualization below

### Completion Button
**Once per day habits (completionsPerDay = 1)**:
- Checkmark button
- Tap to toggle complete/incomplete for today
- Filled with habit color when complete, outline when incomplete

**Multi-completion habits (completionsPerDay > 1)**:
- Plus (+) icon in center
- Circular arc progress indicator around the +
- Arc segments show progress (count / goal)
- Tap to increment by 1
- Long-press to open picker for manual value entry

### Grid Visualization
- 7 rows: Sun, Mon, Tue, Wed, Thu, Fri, Sat (top to bottom)
- 52 columns (1 year of weeks)
- Horizontally scrollable left/right to show previous/later weeks
- Initially scrolled to show current week on the right edge
- Day cell color intensity based on completion:
  - 0 completions: very faint/dark base color
  - Partial completion: medium intensity
  - Full completion (count >= completionsPerDay): full color intensity

### Goal Indicators
Goal indicators summarize progress without outlines:

- **Week completion bar**: A thin habit-colored bar above a week column when either:
  - A weekly goal is configured and met for that week, or
  - Every active day in that week is completed (dates before habit creation are ignored; future dates count and must be completed).

- **Month label highlight**: The month text is tinted with the habit color when any of these are true:
  - A monthly goal is configured and met,
  - A daily goal is configured and every active day in the month is completed (dates before habit creation are ignored; future dates count),
  - A weekly goal is configured and every overlapping week segment in the month meets the weekly goal (partial weeks at the start/end of the month are evaluated against their in-month segment; dates before habit creation are ignored; future dates count).

### Edit Habit Sheet
Presented as a sheet when adding or editing a habit:
- Icon picker button (opens SF Symbols picker)
- Name text field (required)
- Description text field (optional)
- Color picker (grid of preset colors)
- Completions per day (stepper, minimum 1)
- Goal section:
  - Goal value (stepper)
  - Goal period (picker: Day / Week / Month)
  - Goal type (segmented control: Day Basis / Value Basis)
- Save button
- Cancel/close button

### Color Palette
Grid of preset colors for habit selection:
- Row 1 (warm): Coral red, Orange, Yellow, Light yellow, Lime, Green, Teal
- Row 2 (cool): Cyan, Blue, Indigo, Purple, Magenta, Pink, Gray

### Visual Style
- Dark theme background
- Rounded corners on cards and buttons
- Subtle shadows for depth
- Habit color used throughout: icon background, completion button, grid cells, goal indicators

### UX Examples
Take a look at ~/Downloads/habit_tracker_example_images/ for examples of how the UX should look.

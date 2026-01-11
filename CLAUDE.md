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

## Product Requirements

### Habit Configuration
Each habit has the following properties:
- **Icon**: User selects from SF Symbols
- **Name**: Required text field
- **Description**: Optional text field
- **Color**: Selected from preset color palette
- **Completions per day**: 1 for once-daily habits, or higher for multi-completion habits
- **Streak goal**: Configurable goal with:
  - **Period**: Day or Week (no monthly goals)
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

### Streak Outlines
When a streak goal is met, an outline appears in the habit's color:

**Daily Streak Goals**:
- Outline around consecutive days that meet the daily completion goal
- Example: "3 day streak" shows outline around 3+ consecutive completed days

**Weekly Streak Goals**:
- Column outline wraps around the entire week that meets the goal
- Goal evaluation based on streak goal type:
  - Day basis: Count days with at least 1 completion
  - Value basis: Sum all completion counts for the week

### Edit Habit Sheet
Presented as a sheet when adding or editing a habit:
- Icon picker button (opens SF Symbols picker)
- Name text field (required)
- Description text field (optional)
- Color picker (grid of preset colors)
- Completions per day (stepper, minimum 1)
- Streak goal section:
  - Goal value (stepper)
  - Goal period (picker: Day / Week)
  - Goal type (segmented control: Day Basis / Value Basis)
- Save button
- Cancel/close button

### Color Palette
Grid of preset colors for habit selection:
- Row 1 (warm): Coral red, Orange, Yellow, Light yellow, Lime, Green, Teal
- Row 2 (cool): Cyan, Blue, Indigo, Purple, Magenta, Pink
- Row 3 (neutral): Gray, Light gray

### Visual Style
- Dark theme background
- Rounded corners on cards and buttons
- Subtle shadows for depth
- Habit color used throughout: icon background, completion button, grid cells, streak outlines

### UX Examples
Take a look at ~/Downloads/habit_tracker_example_images/ for examples of how the UX should look.

## Development Phases

### Phase 1: Data Layer
- SwiftData models for habits and completions
- ModelContainer configuration
- Basic CRUD operations

### Phase 2: Main List View
- Scrollable habit card list
- Add habit navigation button
- Basic habit card layout (icon, name, placeholder grid)

### Phase 3: Edit Habit Sheet
- Form with all habit configuration fields
- SF Symbols icon picker integration
- Color picker grid component
- Streak goal configuration controls

### Phase 4: Completion Tracking
- Checkmark button for once-daily habits
- Progress ring button for multi-completion habits
- Tap and long-press interactions

### Phase 5: Grid Visualization
- 7x52 grid layout (Sun-Sat rows, week columns)
- Horizontal scrolling with momentum
- Color intensity based on completion state
- Auto-scroll to current week on appear

### Phase 6: Streak Outlines
- Streak calculation logic for day/week periods
- Day cell outline modifier for daily streaks
- Week column outline for weekly streaks

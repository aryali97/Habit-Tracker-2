# UX Upgrade Plan - Home List View

Reference image: `~/Downloads/habit_tracker_example_images/dash_v2.png`

Scope notes:
- Ignore: bottom bar, streak text under habit name, frequency text under habit name.
- Target: home list view styling and layout alignment with the reference.

## Phase 1 - Global Surface + Header
Goal: Align the top-of-screen framing and overall background to the reference.

Atomic goals:
- Add date label at top-left (e.g., "TUESDAY, OCT 24") with matching typography and color.
- Adjust main title placement ("Habits") to align with reference spacing.
- Match app background color to reference (deep charcoal/near-black).
- Add green circular "+" add button in the header (color, size, and spacing to match).
- Ensure header elements (title, search, add) align to a consistent baseline.

## Phase 2 - Habit Card Container Style
Goal: Make cards match the shape, depth, and background tone in the reference.

Atomic goals:
- Match card background color to reference (slightly lighter than app background).
- Increase card corner radius to match the pill-shaped card.
- Add subtle inner/outer shadow to match the soft elevation.
- Adjust card padding to match left/right insets and vertical spacing.
- Ensure card edges feel softer (no harsh borders).

## Phase 3 - Icon + Checkmark/Plus Treatments
Goal: Make icon badges and action buttons circular and visually consistent.

Atomic goals:
- Convert icon background to circular shape with matching size.
- Ensure icon background color matches habit color tone in reference.
- Convert checkmark button background to circular shape.
- Add hazy glow/shadow under completed checkmarks.
- Convert plus button background to circular shape.
- Match plus button stroke/ring radius to arc segment radius.

## Phase 4 - Grid + Month Labels
Goal: Align grid density, spacing, and month label placements with reference.

Atomic goals:
- Add 3-letter month labels above the grid (JAN, MAR, MAY, JUL, SEP, NOV).
- Align month labels to grid columns that correspond to each month start.
- Match grid dot/rect size and spacing to reference.
- Ensure grid color intensity mapping looks like reference.
- Keep grid horizontally scrollable, but initial alignment should match reference.

## Phase 5 - Card Row Layout Polish
Goal: Match the overall row composition for icon, title, and action button.

Atomic goals:
- Align icon, habit name, and action button vertically.
- Match spacing between icon and habit name to reference.
- Match action button size and right padding to reference.
- Ensure card content uses the same left/right inset across all cards.

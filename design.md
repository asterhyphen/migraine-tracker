# Migraine Tracker — Design System & Principles

> **Core Philosophy**: A clinical-grade yet deeply compassionate digital sanctuary designed specifically for individuals experiencing migraines, sensory sensitivity, and photophobia.

---

## 1. Design Philosophy & Medical Context

### 1.1 Sensory-Friendly UX (Photophobia Defense)
Migraine sufferers often suffer from acute photophobia (extreme light sensitivity). Harsh, high-contrast, pure-white backgrounds (`#FFFFFF`) or pure pitch-black AMOLED black (`#000000`) cause optical halation, strobe sensations, and visual aura triggers.
- **Never use pure `#000000`** in Dark Mode: Use deep obsidian navy (`#090D14`).
- **Never use blinding `#FFFFFF` backgrounds** in Light Mode: Use a soothing porcelain mist canvas (`#F6F8FB`).
- Avoid aggressive saturated reds or flashing animations.

### 1.2 Low Cognitive Load During Pain
When logging during an active migraine attack, cognitive capacity and motor control are diminished.
- Primary actions (like "Log Today" or intensity selection) must be unmistakable and easily tappable (minimum 44×44pt touch targets).
- Inputs must feature progressive disclosure: keep the initial screen simple; hide complex advanced analytics behind toggleable or expandable sections.

### 1.3 Reassurance Over Alarmism
- Use warm amber (`#FFB854` / `#D97706`) for moderate risk and cycle warnings rather than alarming alert reds.
- Reserve soft crimson/rose for high severity or clinical Medication Overuse Headache (MOH) indicators.

---

## 2. Color System & Palettes

### 2.1 Dark Theme ("Obsidian Calm")
Designed for nighttime use, dark rooms, and active headache phases.

| Token | Hex Code | Role & Usage |
| :--- | :--- | :--- |
| **Scaffold Background** | `#090D14` | Deep obsidian midnight void; zero eye strain |
| **Card / Surface** | `#111927` | Primary card background with 74%–90% opacity |
| **Elevated Surface** | `#162132` | Nested cards, pill badges, and input fills |
| **Primary** | `#5AE4A8` | Luminous seafoam mint; soothing, energetic, high contrast |
| **On-Primary** | `#04140F` | Deep dark emerald text on primary buttons |
| **Secondary** | `#FFB854` | Warm amber; cycle warnings, secondary highlights |
| **On-Secondary** | `#1E1300` | Deep warm dark text on secondary |
| **Tertiary** | `#7B9BFF` | Soft periwinkle indigo; historical graph accents |
| **Error / Severe** | `#FFFF6B78` | Soft rose coral; indicates pain 7–10 without panic |
| **On-Surface** | `#E8EEF8` | Soft crisp off-white for primary typography |
| **Muted Text** | `#98A6BD` | Secondary metadata (68%–75% visual alpha) |
| **Border / Subtle** | `rgba(232, 238, 248, 0.12)` | Subtle card, chip, and input boundary strokes |

### 2.2 Light Theme ("Daylight Clarity")
Designed for daytime review and clinical clarity without glare.

| Token | Hex Code | Role & Usage |
| :--- | :--- | :--- |
| **Scaffold Background** | `#F6F8FB` | Porcelain mist; glare-free ambient canvas |
| **Card / Surface** | `#FFFFFF` | Crisp white elevated card surface |
| **Elevated Surface** | `#EDF2F7` | Neutral badge and chip fills |
| **Primary** | `#0B826D` | Botanical deep teal; clinical precision, authoritative |
| **On-Primary** | `#FFFFFF` | Crisp white text on primary |
| **Secondary** | `#D97706` | Warm ochre; warning thresholds, secondary stats |
| **On-Secondary** | `#FFFFFF` | White text on secondary |
| **Tertiary** | `#3B6FE8` | Marine sapphire; informational metrics |
| **Error / Severe** | `#DC2626` | Balanced crimson; high pain & medication risks |
| **On-Surface** | `#161F2E` | Deep slate navy; optimum daylight readability |
| **Muted Text** | `#64748B` | Slate 500 for captions and supporting text |
| **Border / Subtle** | `rgba(22, 31, 46, 0.13)` | Delicate container bounding borders |

### 2.3 Birthday Celebration Easter Egg
| Token | Hex Code | Purpose |
| :--- | :--- | :--- |
| **Primary** | `#FF8A3D` | Warm apricot celebration accent |
| **Secondary** | `#FFC857` | Sunlit festive amber |
| **Tertiary** | `#FF6FCF` | Soft wild berry highlight |

### 2.4 Clinical Severity Gradient
- **Mild (1–3)**: `#5AE4A8` (Dark) / `#0B826D` (Light) — Manageable
- **Moderate (4–6)**: `#FFB854` (Dark) / `#D97706` (Light) — Noticeable impairment
- **Severe (7–10)**: `#FF6B78` (Dark) / `#DC2626` (Light) — Incapacitating pain

---

## 3. Typography Architecture

To preserve distinct character across ambient viewing conditions, the app employs different display fonts across themes while sharing an ultra-legible body typeface.

### 3.1 Font Selection by Theme

| Theme | Display / Headings | Body / Captions / Data | Rationale |
| :--- | :--- | :--- | :--- |
| **Dark Theme** | **Space Grotesk** | **Plus Jakarta Sans** | Geometric, tech-forward, open counters; completely eliminates fuzzy halo artifacts on dark OLED screens. |
| **Light Theme** | **Manrope** | **Plus Jakarta Sans** | Modern geometric-humanist blend; rounded terminations provide warm, editorial, non-stark authority. |

### 3.2 Type Hierarchy Scale

| Style | Size | Weight | Tracking | Primary Usage |
| :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 32pt | 800 (Extrabold) | `-0.8` | Screen hero titles, major metric numbers |
| `displayMedium` | 26pt | 700 (Bold) | `-0.5` | Section key stats (e.g. Probability gauge) |
| `titleLarge` | 20pt | 700 (Bold) | `-0.3` | AppBar titles, Sheet headers |
| `titleMedium` | 17pt | 600 (Semibold) | `-0.2` | Card headers, Dialog titles |
| `titleSmall` | 14pt | 600 (Semibold) | `0.0` | Sub-section labels, group headers |
| `bodyLarge` | 15pt | 500 (Medium) | `0.0` | Primary reading text, list tile titles |
| `bodyMedium` | 13pt | 400 (Regular) | `0.0` | Standard body descriptions, notes |
| `bodySmall` | 11pt | 500 (Medium) | `0.1` | Metadata, badges, timestamps, footnotes |
| `labelLarge` | 13pt | 700 (Bold) | `0.2` | Button labels, chip text, Action pills |

---

## 4. Input & Text Normalization Standard

### 4.1 Global Title Case Requirement
All user-entered triggers, causes, categories, and labels must be automatically normalized using the global `StringUtils.toTitleCase()` algorithm:

```dart
import 'package:migraine_tracker/core/utils/string_utils.dart';

// Standalone function or extension method:
final formatted = StringUtils.toTitleCase(userInput);
// or:
final formatted = userInput.toTitleCase();
```

**Normalization Behavior**:
- `"aha tomato"` $\rightarrow$ `"Aha Tomato"`
- `"AHA TOMATO"` $\rightarrow$ `"Aha Tomato"`
- `"sleep-related"` $\rightarrow$ `"Sleep-Related"`
- `"  screen   time  "` $\rightarrow$ `"Screen Time"`

---

## 5. Motion & Interactive Animations

### 5.1 Animation Timing Standards
- **Micro-interactions (Buttons, toggles, chips)**: `180ms – 240ms` with `Curves.easeInOut` or `Curves.easeOutBack`.
- **Sheet & Dialog entrances**: `250ms – 320ms` with `Curves.easeOutCubic`.
- **Page transitions**: Shared custom slide + fade + subtle scale (`0.985` $\rightarrow$ `1.0`) with `Curves.easeOutCubic`.

### 5.2 Disabled vs. Active Button Animation
Buttons that depend on valid user input (e.g., the "Add" button in **Settings / Manage Causes**) must not snap abruptly. They must smoothly animate:
1. **Disabled state**: `opacity: 0.40 – 0.45`, `scale: 0.92`, `onPressed: null`.
2. **Active state**: Smoothly scales to `1.0` with `Curves.easeOutBack` and fades to `1.0` opacity as soon as a non-whitespace character is entered.

```dart
AnimatedOpacity(
  duration: const Duration(milliseconds: 220),
  curve: Curves.easeInOut,
  opacity: hasValidInput ? 1.0 : 0.45,
  child: AnimatedScale(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutBack,
    scale: hasValidInput ? 1.0 : 0.92,
    child: FilledButton.tonal(
      onPressed: hasValidInput ? _onAction : null,
      child: const Text("Action"),
    ),
  ),
)
```

---

## 6. Spatial Grid & Radius Conventions

### 6.1 Spacing Scale
- `4pt`: Micro-spacing, icon-to-label gaps
- `8pt`: Standard inter-item padding, wrap spacing
- `12pt`: Internal card spacing, chip margins
- `16pt`: Standard container padding, form field gaps
- `20pt`: Screen edge margins, major section dividers
- `24pt`: Visual block separations

### 6.2 Corner Radius Matrix
- **Pills / Status Badges**: `20pt` or full circle (`BoxShape.circle`)
- **Action Buttons & Chips**: `12pt – 14pt`
- **Standard Cards & Input Fields**: `14pt – 16pt`
- **Modal Bottom Sheets & Hero Containers**: `20pt – 24pt`

---

## 7. Component Implementation Patterns

### 7.1 Responsive Overflow Prevention
- Never place unconstrained text in a `Row` alongside fixed-width or variable widgets. Always wrap text with `Expanded` or `Flexible` with `overflow: TextOverflow.ellipsis`.
- In interactive button rows (e.g., Risk Forecast confirmation), use `Wrap` with `WrapAlignment.spaceBetween` so buttons wrap gracefully on compact screens without RenderFlex errors.

### 7.2 Modal Bottom Sheets
- Always supply `isScrollControlled: true` and `showDragHandle: true`.
- Wrap content in `PopScope` to guarantee auto-saving even if dismissed via swipe-down or barrier tap.
- Apply `MediaQuery.viewInsets.bottom` to the bottom padding so virtual keyboards never obscure input fields.

---

## 8. Developer Checklist for New Features

When creating a new screen or widget in `migraine_tracker`:

- [ ] **Theme Adherence**: Use `Theme.of(context).colorScheme` rather than hardcoded colors.
- [ ] **Typography**: Use semantic styles (`textTheme.titleMedium`, `textTheme.bodyMedium`) which auto-switch between **Space Grotesk** (Dark) and **Manrope** (Light).
- [ ] **String Normalization**: Call `.toTitleCase()` on user-entered tags, causes, or medication names.
- [ ] **Touch Targets**: Minimum 44×44pt for touch targets; accessible tooltips on action icons.
- [ ] **Keyboard Awareness**: Handle `viewInsets.bottom` on any view containing a `TextField`.
- [ ] **Overflow Resistance**: Ensure all text rows are wrapped in `Expanded` or `Flexible`.
- [ ] **Testing**: Ensure `flutter analyze` reports 0 issues and all unit/widget tests pass.

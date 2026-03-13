# ProcuraX Design System

## Overview

ProcuraX uses a **centralized design system** defined in `lib/theme/app_theme.dart` to ensure visual consistency, accessibility compliance, and maintainability across all screens.

## Architecture

```
lib/
├── theme/
│   └── app_theme.dart          ← Single source of truth (colors, text, spacing, shadows, animations)
├── components/                  ← Reusable UI component library
│   ├── components.dart          ← Barrel export
│   ├── app_button.dart          ← Unified button (primary/secondary/outline/text/danger)
│   ├── app_card.dart            ← Unified card (elevated/outlined/flat)
│   ├── app_input.dart           ← Unified text input with validation
│   ├── loading_state.dart       ← Standardized loading indicator
│   ├── error_state.dart         ← Error state with retry action
│   ├── empty_state.dart         ← Empty state with action button
│   ├── confirm_dialog.dart      ← Confirmation dialog
│   ├── responsive_builder.dart  ← Responsive layout builder
│   └── shimmer_loading.dart     ← Shimmer placeholder loading
```

## Color Palette (`AppColors`)

| Token              | Value       | Usage                         |
| ------------------ | ----------- | ----------------------------- |
| `primary`          | `#1F4DF0`   | Brand blue, CTAs, headers     |
| `primaryLight`     | `#E6EEF8`   | Backgrounds, badges           |
| `primaryDark`      | `#1538B0`   | Pressed states                |
| `success`          | `#10B981`   | Success messages, checkmarks  |
| `error`            | `#EF4444`   | Error states, destructive     |
| `warning`          | `#F59E0B`   | Warnings, pending states      |
| `neutral900`       | `#1B1E29`   | Headings, primary text        |
| `neutral500`       | `#6B7280`   | Secondary/body text           |
| `neutral300`       | `#D1D5DB`   | Borders, dividers             |
| `surface`          | `#F6F7F9`   | Page backgrounds              |

## Typography (`AppTextStyles`)

- Font: **Poppins** (unified, set via `ThemeData.fontFamily`)
- Heading hierarchy: `h1` (28px/bold) → `h2` (24px/bold) → `h3` (20px/600)
- Body text: `bodyLarge` (16px) → `bodyMedium` (14px) → `bodySmall` (12px)
- Functional: `caption`, `overline`, `buttonLarge`, `buttonSmall`

## Spacing (`AppSpacing`)

| Token   | Value | Usage            |
| ------- | ----- | ---------------- |
| `xs`    | 4px   | Tight spacing    |
| `sm`    | 8px   | Small gaps       |
| `md`    | 16px  | Standard gaps    |
| `lg`    | 24px  | Section gaps     |
| `xl`    | 32px  | Large sections   |
| `xxl`   | 48px  | Page-level gaps  |

## Border Radius (`AppRadius`)

- `sm` (8px) — Buttons, badges
- `md` (12px) — Cards, inputs
- `lg` (16px) — Modals, containers
- `xl` (20px) — Large containers
- `full` (100px) — Pills, avatars

## Animations (`AppAnimations`)

- `fast` (200ms) — Micro-interactions, hover
- `normal` (300ms) — Page transitions, expansions
- `slow` (500ms) — Onboarding, reveals
- Curve: `Curves.easeInOutCubic` (standard)

## Page Transitions

All named routes use a unified **fade + slide** transition via `onGenerateRoute` in `main.dart`:
- Duration: `AppAnimations.normal` (300ms)
- Curve: `Curves.easeInOutCubic`
- Effect: Subtle 5% horizontal slide + fade

## Component Library

### `LoadingState`
Replaces raw `CircularProgressIndicator` throughout the app. Supports `fullScreen` and inline modes.

### `ErrorState`
Standardized error display with icon, message, details, and retry button.

### `EmptyState`
Empty content placeholder with icon, title, subtitle, and optional action button.

### `AppButton`
Variants: `primary`, `secondary`, `outline`, `text`, `danger`. All with loading states.

### `AppCard`
Variants: `elevated`, `outlined`, `flat`. Consistent padding, radius, and shadows.

### `ResponsiveBuilder`
Breakpoint-aware layout builder for mobile (< 600px), tablet (< 900px), and desktop.

## Accessibility

- **Semantics**: Applied to navigation drawer tiles, menu buttons, FABs
- **Tooltips**: On all icon buttons (Menu, Notifications, Settings, Create actions)
- **Contrast**: WCAG AA compliant color combinations
- **Screen reader**: Semantic labels on interactive elements

## Integration Status

| Page              | AppColors | Components | Semantics | Transitions |
| ----------------- | --------- | ---------- | --------- | ----------- |
| Dashboard         | ✅        | ✅         | ✅        | ✅          |
| Tasks             | ✅        | ✅         | ✅        | ✅          |
| Notes             | ✅        | ✅         | ✅        | ✅          |
| Notifications     | ✅        | ✅         | ✅        | ✅          |
| Login             | ✅        | —          | —         | ✅          |
| Create Account    | ✅        | —          | —         | ✅          |
| Forgot Password   | ✅        | —          | —         | ✅          |
| Procurement       | ✅        | —          | —         | ✅          |
| Documents         | ✅        | —          | —         | ✅          |
| Meetings          | ✅        | —          | —         | ✅          |
| Communication     | ✅        | —          | —         | ✅          |
| Build Assist      | ✅        | —          | —         | ✅          |
| Settings          | —         | —          | —         | ✅          |

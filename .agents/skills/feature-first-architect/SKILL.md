---
name: feature-first-architect
description: Enforces Feature-First modular architecture and strict Separation of Concerns in Flutter projects. Prevents monolithic files.
---

# Feature-First Modular Architecture Rules

Strictly avoid monolithic files. Follow **Feature-First Architecture** and **Separation of Concerns**:

## 1. Directory Structure
Create a dedicated folder under `lib/features/<feature_name>/` for every screen or module:
```text
lib/
  ├── core/
  │   └── theme/
  │       └── app_colors.dart
  └── features/
      └── home/
          ├── screens/
          │   └── home_screen.dart (Scaffold & layout shell ONLY)
          ├── widgets/
          │   ├── home_calendar_card.dart
          │   └── home_status_bar.dart
          └── controller/
              └── home_controller.dart
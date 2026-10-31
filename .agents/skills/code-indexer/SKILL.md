---
name: code-indexer
description: Maintains and reads CODE_MAP.md before and after any code modification to track file responsibilities and exact line ranges.
---

# Stateful Code Indexing Protocol

`CODE_MAP.md` in the project root is your primary memory index. Execute this strict loop for every task:

## 1. Pre-Execution (Read First)
- ALWAYS read `CODE_MAP.md` before modifying or creating any file.
- If `CODE_MAP.md` does not exist, scan the `lib/` directory and generate it immediately.
- When fixing bugs or refactoring, use the line ranges in `CODE_MAP.md` to locate the exact target code instead of scanning the entire codebase.

## 2. Format Specification
Maintain `CODE_MAP.md` strictly in this format:
- **File:** `lib/features/home/widgets/header_card.dart`
  - **Lines 1-15:** Imports and class declarations.
  - **Lines 16-45:** `buildHeader()` - Top summary card UI.
  - **Lines 46-70:** Date formatting helper methods.

## 3. Post-Execution (Mandatory Sync)
- If line numbers shift due to edits or bug fixes, update the exact line ranges in `CODE_MAP.md` immediately.
- If new files or features are added, append their paths, descriptions, and line ranges to `CODE_MAP.md`.
- NEVER mark a task as complete without syncing `CODE_MAP.md`.
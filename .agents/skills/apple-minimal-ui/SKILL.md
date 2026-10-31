---
name: apple-minimal-ui
description: Enforces Apple Human Interface Guidelines (ultra-minimalism), responsive cross-platform layouts, and strict AppColors theme usage.
---

# Apple Minimalist & Responsive UI Guidelines

## 1. Apple Minimalism (Zero Clutter)
- **No Unnecessary Text:** Never add redundant helper texts, verbose subtitles, or instructional labels. The UI must be self-explanatory.
- **Generous Whitespace:** Avoid cramped layouts. Use clean spacing multiples (`16.0`, `24.0`, `32.0`) for `Padding` and `SizedBox`.
- **Subtle Hierarchy:** Establish visual hierarchy via typography weights (`FontWeight.w600` vs `w400`), surface color contrast, and clean icons rather than heavy borders or excessive dividers.

## 2. Responsive & Multi-Platform Layout
- Target platforms: Mobile, Tablet, Web, and Desktop.
- **NEVER use hardcoded pixel widths** (e.g., `width: 350`).
- Always build adaptive layouts using `LayoutBuilder`, `MediaQuery`, `Expanded`, `Flexible`, and `ConstrainedBox` (e.g., constrain max content width to `600` or `800` on desktop screens).

## 3. Strict Color Palette (`AppColors`)
NEVER use default Flutter colors (`Colors.blue`, `Colors.white`, etc.) or raw inline hex codes. Always import and exclusively use `AppColors`:
- **Backgrounds & Surfaces:** `AppColors.background` (0xFF0A1128), `AppColors.surface` (0xFF131D35), `AppColors.card` (0xFF1B2845), `AppColors.cardLight` (0xFF223354)
- **Accents & Borders:** `AppColors.accent` (0xFF274472), `AppColors.accentLight` (0xFF3A86FF), `AppColors.todayBorder` (0xFF3A86FF), `AppColors.divider` (0xFF1E3050)
- **Calendar / Domain Specific:** `AppColors.cityInner` (0xFF48BFE3), `AppColors.cityOuter` (0xFFF9A826)
- **Typography:** `AppColors.textPrimary` (0xFFFFFFFF), `AppColors.textSecondary` (0xFF8899AA), `AppColors.textHint` (0xFF556677)
- **Semantic Status:** `AppColors.success` (0xFF06D6A0), `AppColors.danger` (0xFFEF476F), `AppColors.warning` (0xFFF9A826)
// ============================================================================
//  AajooHomes — Sand & Indigo palette (WEB / React)
//  Client-approved Option 3. Drop these tokens into src/theme/themeColor.tsx
//  during Phase A1. Indigo #1B2447 replaces purple #881f9b everywhere.
// ============================================================================

// --- Canonical brand tokens (the single source of truth) ---
export const Brand = {
  indigo:    "#1B2447", // PRIMARY — replaces all purple
  indigo600: "#2A356B", // hover / pressed / lighter primary
  sand:      "#EFE7D6", // warm page background
  cream:     "#FFFAF0", // card / surface background
  clay:      "#C16345", // ACCENT ONLY — the one CTA that must pop, "New" badges
  clay600:   "#A8512F", // clay hover
  ink:       "#1B2447", // primary text
  ink2:      "#3D4670", // secondary text
  muted:     "#6B7390", // captions, placeholders
  line:      "#D9CFB8", // warm borders / dividers (never pure gray)
  success:   "#3F6B4E", // verified badges, success states
  danger:    "#C0392B", // errors only
} as const;

// --- Back-compat aliases so existing imports keep working mid-migration ---
// (Existing code imports PurpleThemeColor / FOCUS_COLOR in ~42 files. Pointing
//  them at indigo means most centralized UI flips with zero extra edits.
//  Remove these only in Phase A6 if nothing imports them anymore.)
export const PurpleThemeColor = Brand.indigo;
export const FOCUS_COLOR = Brand.indigo;

export const ThemeColors = {
  primary: Brand.indigo,
  secondary: Brand.success,
  background: Brand.sand,
  text: { primary: Brand.ink, secondary: Brand.muted },
};

// commonFieldSx, menuProps, FieldLabelColor already reference FOCUS_COLOR,
// so they update automatically once FOCUS_COLOR points to indigo. Keep them.


/* ============================================================================
   CSS variables — add to src/index.css so Bootstrap/custom-CSS files and
   Tailwind v4 can consume the same palette.
   ============================================================================

:root{
  --indigo:#1B2447;  --indigo-600:#2A356B;
  --sand:#EFE7D6;    --cream:#FFFAF0;
  --clay:#C16345;    --clay-600:#A8512F;
  --ink:#1B2447;     --ink-2:#3D4670;   --muted:#6B7390;
  --line:#D9CFB8;    --success:#3F6B4E; --danger:#C0392B;
}

@theme{
  --color-brand-indigo:#1B2447;
  --color-brand-indigo-600:#2A356B;
  --color-brand-sand:#EFE7D6;
  --color-brand-cream:#FFFAF0;
  --color-brand-clay:#C16345;
  --color-brand-line:#D9CFB8;
  --color-brand-success:#3F6B4E;
}
============================================================================ */

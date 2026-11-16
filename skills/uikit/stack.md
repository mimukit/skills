## The stack layer

The house default. These are correctness rules, not style preferences.

### Tailwind v4

v4 is CSS-first. Theme lives in `@theme` inside the stylesheet, not in a JS config: `@import "tailwindcss"`, then `@theme`, `@utility`, `@custom-variant`, `@source`, and `@reference` when a separate stylesheet needs the theme.

**Check the version first.** Every v3 name below is still a valid class in v4 that renders *smaller* than the author intended, with no error or warning:

| v3 | v4 |
|---|---|
| `shadow-sm` | `shadow-xs` |
| `shadow` | `shadow-sm` |
| `rounded-sm` | `rounded-xs` |
| `rounded` | `rounded-sm` |
| `blur-sm` | `blur-xs` |
| `blur` | `blur-sm` |
| `outline-none` | `outline-hidden` |
| `ring` | `ring-3` |
| `bg-gradient-to-r` | `bg-linear-to-r` |
| `!text-center` | `text-center!` |

Prefer a generated utility over an arbitrary value (`p-4`, not `p-[16px]`) and a variant over hand-written CSS.

### shadcn/ui

- **Install through the CLI; don't hand-copy component source.**
- **`className` adjusts layout, not appearance.** Margin, width, and grid placement are fine; to change appearance, extend the variant.
- **Semantic tokens only**, meaning `bg-background`, `text-muted-foreground`, `bg-primary`. Never a raw `bg-blue-500` on a shadcn surface.
- **No manual `dark:` overrides.** Semantic tokens already flip.
- **`gap-*` inside a flex or grid container, never `space-x-*`/`space-y-*`.**
- **`size-*` over `w-N h-N`** when both are equal, and `truncate` over the three-property longhand.
- **`cn()` for conditional classes**, never string concatenation, which breaks conflict resolution.
- **No manual `z-index` on overlays.** Dialog, Sheet, Popover, and Dropdown manage their own stacking.
- **Forms compose as `FieldGroup` → `Field`**, and items live inside their group (`SelectItem` in `SelectGroup`, and so on).
- **`asChild` (Radix) or `render` (Base UI) for triggers**, never a nested button inside a trigger.
- **Dialog, Sheet, and Drawer each need a title**, visually hidden if the design doesn't show one.
- **Cards compose fully** (header, title, content, footer) rather than a bare `Card` with markup dumped inside.

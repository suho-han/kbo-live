# Baseball LIVE KR Design System

## 1. Atmosphere & Identity

Baseball LIVE KR feels like a compact game-day command center: glassy, live, and information-dense without becoming noisy. The signature is broadcast glass over a deep blue-black field in dark mode and a crisp stadium-paper surface in light mode, with team colors used as sharp identity accents.

## 2. Color

### Palette

| Role | Token | Light | Dark | Usage |
|------|-------|-------|------|-------|
| Surface/primary | `KboColorToken.backgroundPrimary` | rgb(240, 247, 252) | rgb(10, 18, 26) | Main app background |
| Surface/app top | `KboColorToken.appBackgroundTop` | rgb(230, 247, 250) | rgb(13, 33, 41) | Top of app gradient |
| Surface/app primary | `KboColorToken.appBackgroundPrimary` | rgb(245, 250, 252) | rgb(10, 20, 28) | Main app gradient |
| Surface/app secondary | `KboColorToken.appBackgroundSecondary` | rgb(219, 232, 242) | rgb(8, 13, 20) | Bottom/deep background |
| Surface/card | `KboColorToken.surfaceCard` | white | rgb(28, 38, 46) | Cards and panels |
| Surface/elevated | `KboColorToken.surfaceElevated` | rgb(247, 252, 255) | rgb(38, 48, 59) | Elevated panels |
| Text/primary | `KboColorToken.textPrimary` | rgb(13, 23, 33) | white | Headlines and high-emphasis labels |
| Text/secondary | `KboColorToken.textSecondary` | rgb(69, 87, 107) 76% | white 76% | Supporting labels |
| Text/muted | `KboColorToken.textMuted` | rgb(115, 130, 150) 58% | white 58% | Muted metadata |
| Accent/blue | `KboSemanticColorToken.accentBlue` | rgb(46, 122, 255) | rgb(46, 122, 255) | Active controls and focus |
| Accent/mint | `KboSemanticColorToken.accentMint` | rgb(36, 199, 163) | rgb(36, 199, 163) | Positive live context |
| Status/live | `KboColorToken.statusLive` | rgb(255, 87, 66) | rgb(255, 87, 66) | Live and destructive emphasis |
| Status/scheduled | `KboColorToken.statusScheduled` | rgb(69, 176, 245) | rgb(69, 176, 245) | Scheduled and informational status |
| Status/final | `KboColorToken.statusFinal` | rgb(148, 163, 186) | rgb(148, 163, 186) | Final/neutral status |
| Status/delayed | `KboColorToken.statusDelayed` | rgb(255, 191, 56) | rgb(255, 191, 56) | Warning/delayed status |
| Team primary | `TeamColorPalette.*Primary` | team-specific | team-specific | Team badges, accents, and highlights |

### Rules

- The app supports dark, light, and system appearance. New background, text, card, border, and glass colors must resolve through tokens rather than fixed `Color.white` or `Color.black`.
- Team colors may be used as badge fill, stroke, text, or gradients. If a team primary color is dark, place white text on it for contrast.
- Fixed white or black is allowed only as an intentional contrast color on saturated accent/team/status fills, not as app background or body text.
- New colors belong in Swift token files first, then this document.

## 3. Typography

### Scale

| Level | Size | Weight | Line Height | Tracking | Usage |
|-------|------|--------|-------------|----------|-------|
| Caption | 11pt | medium | system | 0 | Tiny labels |
| Footnote | 13pt | medium | system | 0 | Metadata and compact controls |
| Body | 15pt | regular | system | 0 | Default content |
| Headline | 17pt | semibold | system | 0 | Team names and card labels |
| Score/compact | 24pt | bold | system | 0 | Compact score displays |
| Score/large | 36pt | heavy | system | 0 | Main score displays |
| Menu bar compact | 13pt | bold | system | 0 | Menu bar surfaces |

### Font Stack

- Primary: SF Pro / system font through `Font.system`.
- Mono: system monospaced digits when a component specifically needs tabular alignment.

### Rules

- Use `KboTypographyToken` and `kboFontScale` for scalable text.
- Keep compact panels at body/headline scale; reserve score sizes for game score emphasis.

## 4. Spacing & Layout

### Base Unit

All spacing derives from a 4pt base.

| Token | Value | Usage |
|-------|-------|-------|
| `KboSpacingToken.xSmall` | 4pt | Tight icon-to-label spacing |
| `KboSpacingToken.small` | 8pt | Inline groups and badge padding |
| `KboSpacingToken.medium` | 12pt | Compact card rhythm |
| `KboSpacingToken.large` | 16pt | Standard card padding |
| `KboSpacingToken.xLarge` | 20pt | Comfortable section spacing |
| `KboSpacingToken.xxLarge` | 24pt | Major card spacing |

### Grid

- Layouts are SwiftUI adaptive stacks and grids rather than a fixed web grid.
- Menu bar and dashboard surfaces prioritize stable compact widths and no text overlap.

### Rules

- Use spacing tokens for reusable components.
- One-off layout constants must stay multiples of 4pt unless they match a platform control metric.

## 5. Components

### TeamBadgeView

- Structure: white team logo token plus short team name in a pill.
- Variants: normal and highlighted.
- Spacing: `KboSpacingToken.small` horizontal/inline spacing, 6pt vertical compact padding.
- States: normal and highlighted differ by fill opacity and stroke width.
- Accessibility: token glyph color matches the token border color, and the glyph outline matches the token interior color; all tokens render as centered text for consistent shape balance.
- Motion: no intrinsic motion.

### KboGlassPanel

- Structure: content on a material-backed rounded rectangle.
- Variants: card, elevated, control, navigation.
- Spacing: supplied by caller.
- States: honors reduce-transparency with opaque fallback surfaces.
- Accessibility: border and tint must remain visible on dark backgrounds.
- Motion: no intrinsic motion.

## 6. Motion & Interaction

### Timing

| Type | Duration | Easing | Usage |
|------|----------|--------|-------|
| Micro | 0.16s | snappy | Button press and immediate feedback |
| Standard | 0.28s | smooth | Section reveal |
| Score change | 0.24s | spring, 0.18 bounce | Score updates |
| Live pulse | 1.1s | ease-in-out repeat | Live status pulse |

### Rules

- Use `KboMotionToken` for reusable motion.
- Prefer opacity and transform changes; avoid animating layout.
- Respect platform accessibility settings such as reduce transparency.

## 7. Depth & Surface

### Strategy

Mixed: native SwiftUI materials plus tonal gradients, subtle borders, and restrained shadows.

| Level | Token | Usage |
|-------|-------|-------|
| Card | `KboGlassPanelStyle.card` | Default game and metric cards |
| Elevated | `KboGlassPanelStyle.elevated` | Featured or primary cards |
| Control | `KboGlassPanelStyle.control` | Compact controls |
| Navigation | `KboGlassPanelStyle.navigation` | Navigation surfaces |

### Rules

- Glass panels use `KboGlassToken` material, tint, border, and shadow helpers.
- Team badges use team-color fills and strokes, not generic card borders.

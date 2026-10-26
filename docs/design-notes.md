# Bearing interface

We kept one main action at each step. Home has an arm-raise shortcut, the routine library, custom check-ins, and My plan. We use native SwiftUI controls, a warm paper background, forest green buttons, and a simple line mark. The light and dark app icons come from `scripts/generate-app-icon.swift`. The welcome heading and main result use a serif font. Instructions and controls use the system font.

## Palette

| Role | Light | Dark |
| --- | --- | --- |
| Page | #F6F5EF | #131C19 |
| Surface | #FFFFFF | #202C26 |
| Main text | #203C32 | #F0F3EB |
| Supporting text | #52645B | #B9C9BF |
| Action | #285442 | #A6D4B6 |
| Quiet surface | #E6EDE4 | #2B3D32 |
| Delete action | #9F302B | #FFB4A8 |

The palette is deliberately limited. No gradients, stock photos, decorative charts, or dashboard scores are used. Color does not convey readiness by itself: checks also show a shape and a word.

## Flow

1. Home gives the arm raise one clear entry point. History and privacy are quiet navigation rows. Voice, voice speed, and language stay directly available. Try voice previews the saved speed.
2. Prepare offers large arm choices, numbered instructions, repeat speech, and a persistent Continue button. At accessibility text sizes, the arm choices stack vertically.
3. Record shows attempt progress, the current instruction, a portrait preview, and explicit setup checks. Start when ready stays at the bottom. Its explanation and the helper start control scroll with the page. The waiting state keeps cancellation reachable. The preview preserves its 9:16 ratio so the display transform stays aligned with the camera. Review removes the preview and explains each attempt.
4. Result gives the projected angle first, followed by a plain number explanation, measurement details, and personal starting point. The disclaimer sits beside the result. PDF creation stays explicit and remains available at the bottom. Done returns home; the other-arm action preselects the opposite side.
5. Empty history explains what belongs there and offers a direct start. Saved rows separate dates, sides, angles, and counted attempts.

All pages scroll. Content has a maximum reading width. No essential instruction depends on animation. English and Spanish use the same layout. Large type, screen-reader labels, native navigation, and light/dark appearances remain supported.

## Test data

The optional UI test session exists only in a DEBUG simulator build with both the fresh in-memory store and sample-session arguments. It cannot enter a persistent store or an iPhone release build. Screenshot results using it are explicitly named TestFixture. They are not volunteer or device measurements.

## Three sentences for a judge

Bearing guides a person through one arm movement at a time. Large controls, clear instructions, and English or Spanish help people follow each step. The result explains what was measured and lets the person choose what to share.

## Verification approach

The palette test resolves the actual app colors in light and dark appearances. Every text/background pair, including button text, must reach a contrast ratio of at least 4.5:1. The home screen also uses automated control, layout, and Dynamic Type checks.

The result audit checks the initial screen for element detection, hit regions, clipped text, and Dynamic Type. The lower actions receive hit-region and clipping checks. A separate largest-text test confirms that Done grows beyond its standard height and that export and completion remain reachable. Its automated contrast scan is excluded: on iOS 18.6, it sampled black pixels for text outside the visible scroll region, behind the navigation or PDF action bars. Contrast on this screen is instead covered by the palette test and visual inspection of the initial result and lower explanation. Despite requesting only the other audit categories, the additional dark home run still reported contrast. The longer home screen has the same contrast-scanner limitation: the dark audit sampled only the home-indicator area for an offscreen Privacy and data label. Home contrast is also checked through palette calculations and screenshots. No issue handler suppresses failures, and this test limitation does not change the app's accessibility tree.

The prior arm-only clean run passed 70 unit tests and 12 interface tests. The expansion passed 96 unit tests and 18 interface tests, with affected views checked again after visual polish. The test runner is reinstalled when needed to prevent stale simulator test binaries. The final iPhone Release build is unsigned; camera alignment and hands-on usability still require a real phone.

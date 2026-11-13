# clutter — app icon brief

Working document for drawing icon options. Source of truth: `RAIDETEAM_GUIDELINES.md` §5.3, §5.5, §7.

## 1. The idea

**One photo leaves the pile: clutter turns a messy stack of photos into a clear, sorted one, one card at a time.**

## 2. Hard constraints

- **Format:** Icon Composer layers: exactly **1 background layer** + **1–3 foreground layers**. Vector only, crisp edges.
- **Canvas:** 1024×1024 px, square, **unmasked** (the system applies the rounded shape). Keep all key content inside the central ~820×820 px area; nothing important within 100 px of the edge.
- **Content:** no text or letters (not even a "c"), no photos or photo-like imagery (no mountains, suns, landscapes inside the cards), no copies of app UI (no buttons, no "keep"/"delete" labels, no trash glyph lifted from the app or SF Symbols).
- **Effects:** no custom shadows, highlights, bevels, blurs, glows, or fake glass. Flat fills only; the system adds Liquid Glass depth itself. Layer separation creates depth, not drawn shadows.
- **Color:** mostly black and white (plus greys). **At most one accent color** in the entire icon, used on a single element. Background is one solid color or one simple two-stop linear gradient.
- **Shapes:** few shapes (aim for 2–4 total). No hairlines: minimum stroke/gap ~40 px on the 1024 canvas. All corners rounded (minimum corner radius ~48 px on cards); no sharp points.
- **Legibility:** must still read at 40×40 px (Spotlight/Settings). Test by downscaling.
- **Appearances:** must work in **default (light), dark, clear, and tinted**. Same elements in every variant; build dark from light by swapping fills only. In tinted/clear mode the system flattens colors to luminance, so the idea must survive **without** the accent (shape and position carry the meaning, not color).
- **Originality (§7, 4.1/5.2.1):** must not resemble Apple's Photos icon (no multicolor petals/flower, no rainbow), nor other photo-cleaner/swipe apps (no flame, no heart/X pair, no brush/broom, no sparkles, no generic tilted-card-with-checkmark), nor Apple's Files/Notes icons.

## 3. Concept directions

Coordinates are on the 1024×1024 canvas, origin top-left. "Card" = rounded rectangle, portrait 3:4 unless noted, corner radius ~64 px.

### A. "the one that leaves" (swiped card)

- **Background layer:** solid fill. Light: white. Dark: near-black (#111).
- **Foreground layer 1 — stack:** two cards stacked, each 400×520 px, centered at (470, 540). Back card offset +28 px right / −28 px up from the front card; both upright (0°). Light: back card mid grey (#C7C7CC), front card dark grey (#3A3A3C). Dark: back #48484A, front #8E8E93.
- **Foreground layer 2 — leaving card:** one card, same size, rotated −14°, centered at (620, 470) so it sits ~40% off the stack, as if flicked up and to the right. Drawn in the **single accent** (warm yellow, approx. #FFCC00 light / #FFD60A dark) or, for a monochrome option, solid black (light) / white (dark).
- **Why:** the swipe gesture in one image: a pile, and one card being flicked away. Reads as "sorting, one at a time".

### B. "less" (big stack to small stack)

- **Background layer:** vertical gradient. Light: #FFFFFF top → #E5E5EA bottom. Dark: #2C2C2E top → #000000 bottom.
- **Foreground layer 1 — messy pile (left):** three cards 260×340 px, centered around (360, 560), rotated −12°, +4°, +16°, overlapping loosely. Light: greys #AEAEB2 / #8E8E93 / #636366. Dark: #636366 / #8E8E93 / #AEAEB2.
- **Foreground layer 2 — tidy card (right):** one card 260×340 px, upright, centered at (680, 500). Light: black. Dark: white. Optional accent: none (pure monochrome direction).
- **Why:** before/after in one glance: disorder on the left, a single orderly card on the right. "clearing clutter" without any symbol.
- **Risk to check:** at 40 px the pile can blur into one blob; keep gaps between cards ≥ 40 px where visible.

### C. "the gap" (row with one missing)

- **Background layer:** solid. Light: #F2F2F7. Dark: #000000.
- **Foreground layer 1 — grid:** 3×3 grid of rounded squares, each 200×200 px, radius 48 px, gap 56 px, grid centered on the canvas (total 712×712). Light: #1C1C1E. Dark: #F2F2F7.
- One cell (top-right, row 1 col 3) is **removed** from the grid layer.
- **Foreground layer 2 — lifted tile:** that missing tile drawn separately, same size, shifted +60 px right / −60 px up and rotated +12°, in the **accent** (warm yellow as in A) or mid grey for mono.
- **Why:** a library grid with one item being taken out: cleaning up, item by item. A grid abstracts "photo library" without copying Photos.
- **Risk to check:** grid must not look like a generic launcher/calculator; keep tiles chunky and only 9.

### D. "inbox" (cards dropping into a tray)

- **Background layer:** solid. Light: white. Dark: #111.
- **Foreground layer 1 — tray:** a wide U-shape (rounded rectangle 640×240 px, top edge open, wall thickness 64 px, outer radius 80 px), centered horizontally, bottom edge at y=820. Light: black. Dark: white.
- **Foreground layer 2 — falling card:** one card 300×380 px, rotated −10°, centered at (512, 420), its bottom ~60 px above the tray opening. Accent (warm yellow) or mid grey (#8E8E93) for mono.
- **Why:** mirrors the app's core loop: photos go into a deletion inbox to be cleared. Neutral tray, not a trash can, so it is not a copy of any system glyph.
- **Risk to check:** must not read as a printer, a mailbox, or Apple Mail. Keep the tray shallow and plain.

### E. "split" (two directions)

- **Background layer:** horizontal split, hard edge at x=512. Light: left half #1C1C1E, right half #FFFFFF. Dark: left #000000, right #3A3A3C.
- **Foreground layer 1 — card:** one card 380×500 px, centered at (512, 512), rotated +8°, straddling the split. Fill: mid grey (#8E8E93) in both light and dark, so it contrasts with both halves.
- **Foreground layer 2 (optional) — accent dot:** a 120 px circle at the card's top-left corner area (centered ~(390, 330)) in the accent, signalling "decision".
- **Why:** keep vs delete, left vs right: one photo at the moment of decision. Black/white split matches the app's look.
- **Risk to check:** the split background disappears in clear/tinted mode; the tilted card alone must still read. Consider this the boldest, least safe option.

### F. "one clean card" (minimal monochrome)

- **Background layer:** vertical gradient. Light: #FFFFFF → #F2F2F7. Dark: #1C1C1E → #000000.
- **Foreground layer 1 — card:** one portrait card 460×600 px, centered at (512, 530), upright. Light: black. Dark: white.
- **Foreground layer 2 — corner fold / dot:** a single circle 140 px, centered at the card's top-right corner (~(742, 230)), overlapping the corner, in the accent (warm yellow). No other marks.
- **Why:** the app's core view reduced to its essence: one photo at a time, nothing else. Calm and Apple-like; the dot marks "this one is being decided".
- **Risk to check:** may be too generic on its own; judge against A and C.

## 4. Avoid

- Apple Photos look: petals, flower, multicolor/rainbow, pinwheel.
- Trash cans, brooms, brushes, sparkles, magic wands, checkmarks, X marks, hearts, flames.
- Landscape pictograms (mountain + sun) inside cards; any real photo.
- Text, letters, numbers, app UI buttons, SF Symbols copied as-is.
- More than one accent color; color used only for decoration; red as the accent (reads as "destructive"/notification badge).
- Drawn shadows, glows, gloss, glass, bevels, outlines thinner than ~40 px, sharp corners.
- Busy compositions: more than ~4 shapes, or content touching the canvas edge.
- Inventing new colors per variant: stick to the hex values above (the §5.3 "no hard-coded colors" rule applies to app code, not to icon artwork). Accent is the same warm yellow in every concept.

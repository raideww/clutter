# raideteam — Guidelines for Agents

> Read this before starting any task. Every decision you make — product, design, code, copy — must be consistent with this document. When in doubt, choose the simpler option.

---

## 1. Who we are

**raideteam** builds **free alternatives to paid iPhone utilities**, with a clean, modern design built on Apple's **Liquid Glass** language.

- **Platform:** iPhone (iOS) only.
- **Price:** every app is **free**. No paid tiers, no in-app purchases, no subscriptions.
- **Ads:** none. Ever.
- **Costs:** zero ongoing costs for the team. No servers, no backend, no paid third-party services.

This document is a **universal guideline** that applies to every app we build.

---

## 2. Why we exist

### Goal
1. Build a **portfolio of real apps on the App Store**.
2. Give people the useful utilities they deserve — **for free**.
3. Practice and sharpen our craft while helping the community.

### Audience
Regular iPhone users who need a specific utility. They are not technical and not looking for power-user features. We make their life easier with a beautiful interface and simple functionality.

### Why users won't build it themselves
- Publishing requires the **Apple Developer Program ($99/year)**; without it, self-built apps must be constantly re-installed from a laptop.
- It takes time, motivation, and tools (e.g. an AI subscription) that a regular person won't invest for a single task.

We absorb that cost and effort so they don't have to.

---

## 3. What apps we build

Target apps must meet **all** of these criteria:

| Criterion | Requirement |
|---|---|
| Type | Utility that runs entirely on the phone |
| Infrastructure | No server, no account, no cloud sync required |
| Running costs | Zero |
| Complexity | Simple to use; no heavy architecture or feature sprawl |
| Business model | Free alternative to an existing paid app |

If an idea needs a backend, a login, or recurring costs — **it is out of scope**.

---

## 4. Product principles

1. **Get in → do the task → get out.** The user opens the app, starts their task immediately, and leaves as soon as it's done. No onboarding walls, no sign-ups, no upsells.
2. **One app, one job.** Do the core job extremely well. Cut everything else.
3. **Zero friction.** The first screen should already be useful. Minimize taps to the main action.
4. **Native first.** Behave like an Apple app. Use system patterns users already know.
5. **Respect the user.** No ads, no tracking, no analytics, no data leaving the device.
6. **Simple architecture.** Small, readable codebase. Prefer native frameworks over dependencies.

---

## 5. Design system

### 5.1 Reference apps
Design like Apple's own iPhone apps: **Notes, Calendar, Files (the iPhone counterpart of Finder), Photos, Settings**. If an Apple app solves a similar UI problem, follow its pattern.

### 5.2 Liquid Glass
- Adopt Apple's **Liquid Glass** design philosophy fully, which means using the glass material itself **with restraint**, as Apple's HIG requires.
- **Two layers:** content at the bottom, and a Liquid Glass layer for **controls and navigation** (tab bars, toolbars, navigation bars, sheets, popovers) floating above it.
- **Never put Liquid Glass in the content layer.** Don't use it for backgrounds, cards, list rows, or content blocks.
- **Use system components first.** Standard SwiftUI bars, buttons, sheets, and menus adopt Liquid Glass automatically. Don't fake glass with custom blurs.
- **Custom glass sparingly.** Apply `glassEffect` only to the few most important custom controls. Overusing glass distracts from content.
- **Variants:** use the default (regular) glass in most places. Use **clear** glass only over rich media such as photos and video. If the media behind it is bright, add a dark dimming layer of about 35%.
- Let content run edge to edge under the bars. The system's scroll edge effect keeps the bars legible.
- Follow Apple's **Human Interface Guidelines** for spacing, layout, and motion.

### 5.3 Color
- **Black and white dominate,** achieved through **semantic system colors** (`.primary`, `.secondary`, `Color(.systemBackground)`, `Color(.label)`, and so on). **Never hard-code** `#000000`/`#FFFFFF` or other system color values: semantic colors adapt to Light/Dark mode and Increase Contrast automatically.
- **Accent colors are rare.** Use them only for status indicators or the primary action. For a primary action, color the button's background rather than its text or symbol.
- Destructive actions use the system role (`Button(role: .destructive)`), not a hand-picked red.
- Liquid Glass has no color of its own. Tint glass only when a control truly needs emphasis.
- **Never rely on color alone** to convey state or meaning. Pair it with a symbol, shape, or text label.
- Every custom color needs light, dark, and increased-contrast variants.
- Never use color for decoration.

### 5.4 Typography & layout
- Use the system font (SF Pro) via **built-in text styles** (`.body`, `.headline`, `.title`, and so on), so Dynamic Type works automatically. Don't use fixed point sizes.
- Body text defaults to **17 pt**; nothing goes below **11 pt**.
- Prefer Regular, Medium, Semibold, or Bold weights. **Avoid Ultralight, Thin, and Light**: they're hard to read.
- Use one typeface. Create hierarchy with text styles and weight, not more fonts.
- Generous whitespace, clear hierarchy, few elements per screen.
- Use SF Symbols for in-app icons.

### 5.4.1 Lowercase everything
- **All interface text is lowercase**: titles, navigation bars, buttons, tabs, labels, section headers, alerts, empty states, settings, onboarding — every string the user sees.
  - ✅ `delete`, `select all`, `settings`, `no photos left`
  - ❌ `Delete`, `Select All`, `Settings`, `No Photos Left`
- Write strings lowercase in the source/localization files. Don't rely on `.textCase(.lowercase)`, because it can break proper nouns and some languages.
- Override SwiftUI's default uppercase section headers with `.textCase(nil)`.
- Permission prompts (`Info.plist` usage descriptions) are lowercase too.
- Exception: text drawn by the system that we can't control (e.g. system share sheet, system alerts' built-in buttons) — leave as is.
- This intentionally deviates from Apple's HIG, which *recommends* title-style capitalization for buttons. The HIG is guidance, not a review rule; it asks for a consistent style, so lowercase must be applied **everywhere, with no mixing**.

### 5.5 App icons
- **Simple and minimalist.** Use a minimal number of shapes, mostly black/white, with at most one accent color, on a simple solid or gradient background.
- Build icons in **Icon Composer** (included with Xcode) as layers: one background plus one or more foreground layers. Vector graphics, with clearly defined edges, unmasked (the system applies the rounded shape). Canvas 1024×1024 px, main content centered.
- Support all four Home Screen appearances: **default, dark, clear, and tinted**. Keep the same elements across them; build the dark variant from the light one.
- **No text** in the icon, and no photos or copies of UI elements.
- **No custom effects** (shadows, highlights, bevels, blurs, glows). The system adds Liquid Glass highlights and depth itself.
- Avoid very thin lines and sharp corners. The icon must read clearly at small sizes and fit next to Apple's own icons.

### 5.6 Accessibility
- **Contrast:** at least **4.5:1** for text up to 17 pt, and **3:1** for 18 pt+ or bold text. Check in both Light and Dark mode.
- **Tap targets:** **44×44 pt** by default, **28×28 pt** absolute minimum.
- **Dynamic Type:** the layout must adapt to every text size, including accessibility sizes (at least 200%), with minimal truncation.
- **VoiceOver:** every control and image has a meaningful label (lowercase, like the rest of the UI).
- **Reduce Motion:** replace movement and zoom with fades, and tone down springs and bounces.
- **Reduce Transparency / Increase Contrast:** system components handle these automatically. Verify any custom glass or colors still look right with these settings on.

---

## 6. Naming

- App names are **one or two words maximum**.
- App names are **always lowercase** — on the Home Screen, in the App Store, and inside the app (e.g. `photo box`, `scan`).
- Names should be clear, short, and describe the job.
- **App Store listing name:** append the team name to the right of the app name so the name is unique and accepted by the App Store:
  - `<appname> raideteam`
- Team name is always written in lowercase: **raideteam**.

---

## 7. App Store compliance

Based on the App Store Review Guidelines. Breaking these leads to rejection.

- **Lowercase names are allowed.** No rule covers letter case. App Store Connect requires the name to be **2–30 characters**, so `<appname> raideteam` must fit in 30 characters (`raideteam` + space takes 10).
- **Unique name (2.3.7).** Don't stuff the name, subtitle, or keywords with trademarks, popular app names, or prices (no "free" in the name).
- **No copycats (4.1, 5.2.1).** We build free *alternatives*, not clones. Never use another app's name, icon, branding, screenshots, or copy its UI one-to-one. Never mention the paid app we replace in the name, subtitle, or metadata.
- **No spam (4.3).** Apple rejects new apps in saturated categories (flashlight, simple timers, wallpapers, sound effects, etc.) unless they're meaningfully better. Each app needs a clear reason to exist.
- **Real utility (4.2).** The app must be genuinely useful and "app-like," not a thin wrapper.
- **Accurate metadata (2.3).** Description and screenshots must show what the app really does.
- **Name consistency (2.3.8).** The Home Screen name, App Store name, and icon must match. The Home Screen name (`CFBundleDisplayName`) is just `<appname>`, without `raideteam`.
- **Check on a real device.** Developers have reported the App Store changing letter case of the Home Screen name after install. After each TestFlight build, confirm the name still shows in lowercase.

---

## 8. Technical guidelines

- **Language / UI:** Swift + SwiftUI, targeting the latest iOS SDK to get native Liquid Glass.
- **Data:** stored locally on device only (e.g. SwiftData, UserDefaults, or the system's own stores like the Photos library).
- **Networking:** none, unless absolutely required by a system API.
- **Dependencies:** avoid third-party packages; use Apple frameworks.
- **Permissions:** ask only for what the core job needs, at the moment it's needed, with a clear explanation.
- **Privacy:** App Store privacy label must be **"Data Not Collected."**
- **No** ads SDKs, analytics SDKs, crash-reporting services that send data off-device, or accounts.
- Keep the architecture simple — no over-engineering for a small utility.

---

## 9. Agent checklist

Before shipping any feature, screen, or app, confirm:

- [ ] The app is free, with no ads and no in-app purchases.
- [ ] Everything runs on-device; no server or ongoing cost.
- [ ] A user can start the main task within seconds of opening the app.
- [ ] The design feels like a native Apple app; Liquid Glass is used only on controls/navigation, never in content.
- [ ] Only semantic system colors are used (nothing hard-coded); state is never shown by color alone.
- [ ] Black and white dominate; accent color is used only where it matters.
- [ ] The icon is simple, made in Icon Composer, has no text, and works in default/dark/clear/tinted.
- [ ] The name is one or two words, lowercase; App Store name is `<appname> raideteam`.
- [ ] Every piece of interface text is lowercase.
- [ ] App Store name is ≤ 30 characters, with no trademarks, prices, or other apps' names; the app isn't a clone.
- [ ] No unnecessary features, screens, or dependencies were added.
- [ ] No user data leaves the device.
- [ ] Light/Dark mode, Increase Contrast, Reduce Motion, Dynamic Type (accessibility sizes), and VoiceOver work; tap targets ≥ 44 pt.

---

## 10. Summary in one line

**raideteam makes free, beautiful, Apple-style iPhone utilities that run fully on-device — open, done, close.**

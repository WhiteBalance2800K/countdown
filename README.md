# Countdown

English | [简体中文](README.zh-CN.md)

Countdown is a small macOS SwiftUI app for tracking expiry dates, renewals, and time-sensitive items.

Current version: `v0.7`

## Screenshots

<p align="center">
  <img src="Resources/screenshot-dashboard.png" alt="Countdown dashboard" width="45%">
  <img src="Resources/screenshot-settings.png" alt="Countdown settings" width="45%">
</p>

## What's New In v0.7

- Fixed manual card rearranging so an item near the top can be dragged to the end.
- Removed the heavy translucent drag shadow and replaced it with a subtle outline feedback.
- Kept the smooth spring movement for neighboring cards while dragging.

## What's New In v0.6

- Added notes for countdown items.
- Added per-item custom reminder offsets, such as `30, 7, 1, 0` days before expiry.
- Fixed editing overdue items so their original expiry date is not accidentally reset to today.
- Added nearest due items to the macOS menu bar menu.
- Added Settings shortcuts for opening the data folder and backup folder in Finder.

## What's New In v0.5

- Made card rearranging substantially smoother with spring layout animation.
- Reduced reorder-mode overhead by saving the new order once when the drag is dropped.
- Replaced constant card jiggle with a calmer drag lift interaction.

## What's New In v0.4

- Added automatic backups for countdown data and a recovery prompt when `items.json` is damaged.
- Added a macOS menu bar entry for opening Countdown, adding an item, opening settings, and quitting.
- Added a Launch at Login option in Settings.
- Built and attached a compressed `.app` bundle for the GitHub Release.

## What's New In v0.3

- Split the documentation into separate English and Simplified Chinese README pages.
- Kept English as the default GitHub README.
- Adjusted the screenshots section so the two images are displayed side by side at half width.
- Updated release metadata for `v0.3`.

## What's New In v0.2

- Added a language switcher in Settings.
- Added 10 app languages: Simplified Chinese, English, Spanish, Hindi, Arabic, French, Bengali, Portuguese, Russian, and Japanese.
- Localized the main dashboard, add/edit dialog, settings dialog, date display, and Bark push text.
- Connected the selected language to native date formatting and the macOS date picker locale.
- Kept all localization preferences local through `UserDefaults`.

## Features

- Add, edit, and delete countdown items.
- Add notes to countdown items.
- Enter an expiry date directly or by remaining days.
- Set custom reminder offsets per item.
- Compact card layout with color-coded ring progress.
- Manual drag ordering with a lightweight arrange mode.
- One-click ordering by near or far expiry dates.
- Light and dark mode support through native macOS appearance.
- Language switcher with 10 app languages.
- Optional Bark push reminders based on each item's custom reminder offsets.
- Menu bar entry with nearest due items and quick actions.
- Optional launch at login.
- Local-first persistence with no account or external service required for core usage.

## Persistence

Countdown keeps user data outside the source tree:

- Countdown cards: `~/Library/Application Support/Countdown/items.json`
- Countdown data backups: `~/Library/Application Support/Countdown/backups/`
- UI, language, and push preferences: macOS `UserDefaults` via SwiftUI `@AppStorage`
- Launch at login: macOS Login Items through `SMAppService`

The repository does not include personal countdown data. Local backups and build outputs are excluded by `.gitignore`.

## Requirements

- macOS 13 or later
- Swift 6.2 or later

## Run From Source

```bash
swift run
```

## Build The App Bundle

```bash
bash scripts/build_app.sh
open dist/Countdown.app
```

The generated app bundle is written to `dist/Countdown.app`, and the release archive is written to `dist/Countdown-v0.7-macOS.zip`.

## Bark Push Setup

1. Install Bark on your iPhone and copy the Bark push URL.
2. Open Countdown settings.
3. Paste a URL like:

```text
https://api.day.app/your-key
```

Countdown appends the notification title and body automatically.

Each countdown item can define custom reminder offsets, for example:

```text
30, 7, 1, 0
```

This means Countdown can remind you 30 days, 7 days, 1 day, and 0 days before the item expires.

## Project Structure

```text
Sources/Countdown/        SwiftUI app source
Resources/                App icon and public screenshots
scripts/build_app.sh      Local .app bundle build script
```

## License

MIT. See [LICENSE](LICENSE).

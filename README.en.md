# Countdown

English | [简体中文](README.md)

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![Version](https://img.shields.io/badge/version-v0.9.3-green)
![License](https://img.shields.io/badge/license-MIT-blue)

Countdown is a small local-first macOS SwiftUI app for tracking expiry dates, renewals, recurring reminders, and other time-sensitive items.

Current version: `v0.9.3`

[Download Latest Release](https://github.com/WhiteBalance2800K/countdown/releases)

## Screenshots

<p align="center">
  <img src="Resources/dashboard.png" alt="Countdown dashboard" width="45%">
  <img src="Resources/screenshot-settings.png" alt="Countdown settings" width="45%">
</p>

## Features

- [x] Track expiry dates, renewals, deadlines, and recurring items.
- [x] Add, edit, archive, restore, and delete countdown items.
- [x] Enter an expiry date directly or by remaining days.
- [x] Add notes, category presets, and custom categories to each countdown item.
- [x] Pick Bark reminder dates with quick choices, plus/minus controls, or number input.
- [x] Use repeat rules for monthly, quarterly, yearly, or custom day intervals.
- [x] Renew recurring countdown items with one click.
- [x] Filter by active, all, 30-day, overdue, archived, and category.
- [x] Archive completed items without deleting them.
- [x] Compact card layout with color-coded ring progress.
- [x] Manual drag ordering with arrange mode.
- [x] One-click ordering by nearest or farthest expiry date.
- [x] Native light and dark mode support.
- [x] Manual system, light, and dark appearance modes.
- [x] Keep the main window above other windows when needed.
- [x] Immersive mode with only countdown rings and a transparent window background.
- [x] Language switcher with 10 app languages, plus GitHub and feedback shortcuts in Settings.
- [x] Optional Bark push reminders.
- [x] Menu bar entry with nearest due items and quick actions.
- [x] Optional launch at login.
- [x] Local-first persistence with no account required.

## Use Cases

Countdown is useful for tracking:

- subscription renewals
- domain and certificate expiry dates
- warranty and insurance deadlines
- membership renewals
- personal deadlines
- recurring reminders
- items that should not be forgotten before they expire

## Roadmap / Todo

- [ ] Add native macOS notifications as an alternative to Bark push.
- [ ] Add iCloud sync or optional file-based sync for users with multiple Macs.
- [ ] Add import and export support for JSON or CSV files.
- [ ] Add calendar export support, such as `.ics` files.
- [ ] Add more dashboard views, such as grouped-by-category and timeline views.
- [ ] Add smarter recurring rules, such as every N months or custom weekdays.
- [ ] Add batch editing for categories, reminder offsets, and archive status.
- [ ] Add keyboard shortcuts for adding, archiving, filtering, and arranging items.
- [ ] Add stronger data recovery tools for damaged or manually edited data files.
- [ ] Add automated tests for item storage, repeat rules, reminders, and backup recovery.

## Download

Download the latest app bundle from the [Releases](https://github.com/WhiteBalance2800K/countdown/releases) page.

1. Download `Countdown-v0.9.3-macOS.zip`.
2. Unzip it.
3. Move `Countdown.app` to `/Applications`.
4. Open Countdown from Finder or Launchpad.

## Requirements

- macOS 13 or later
- Swift 6.2 or later, only required when building from source

## Run From Source

```bash
swift run
```

## Build The App Bundle

```bash
bash scripts/build_app.sh
open dist/Countdown.app
```

The generated app bundle is written to:

```text
dist/Countdown.app
```

The release archive is written to:

```text
dist/Countdown-v0.9.3-macOS.zip
```

## Bark Push Setup

1. Install Bark on your iPhone and copy your Bark push URL.
2. Open Countdown settings.
3. Paste a URL like:

```text
https://api.day.app/your-key
```

Countdown appends the notification title and body automatically.

Each countdown item can define Bark reminder dates. Use the quick buttons for common choices such as due day, 1 day before, 7 days before, or 30 days before. For custom timing, use the plus/minus controls or number input to set how many days before expiry the reminder should fire.

## Data Storage & Privacy

Countdown keeps user data outside the source tree:

- Countdown items: `~/Library/Application Support/Countdown/items.json`
- Data backups: `~/Library/Application Support/Countdown/backups/`
- UI, language, and push preferences: macOS `UserDefaults` via SwiftUI `@AppStorage`
- Launch at login: macOS Login Items through `SMAppService`

Countdown does not require an account for core usage. Bark push is optional. The repository does not include personal countdown data. Local backups and build outputs are excluded by `.gitignore`.

## Project Structure

```text
Sources/Countdown/        SwiftUI app source
Resources/                App icon and public screenshots
scripts/build_app.sh      Local .app bundle build script
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).

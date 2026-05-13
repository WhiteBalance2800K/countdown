# Countdown

English | [简体中文](README.zh-CN.md)

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![Version](https://img.shields.io/badge/version-v0.8-green)
![License](https://img.shields.io/badge/license-MIT-blue)

Countdown is a small local-first macOS SwiftUI app for tracking expiry dates, renewals, recurring reminders, and other time-sensitive items.

Current version: `v0.8`

[Download Latest Release](https://github.com/WhiteBalance2800K/countdown/releases)

## Screenshots

<p align="center">
  <img src="Resources/screenshot-dashboard.png" alt="Countdown dashboard" width="45%">
  <img src="Resources/screenshot-settings.png" alt="Countdown settings" width="45%">
</p>

## Highlights

- Track expiry dates, renewals, deadlines, and recurring items.
- Add notes, categories, and links to each countdown item.
- Set custom reminder offsets such as `30, 7, 1, 0` days before expiry.
- Use repeat rules for monthly, quarterly, yearly, or custom day intervals.
- Search and filter countdown items by status, category, note, or link.
- Archive completed items without deleting them.
- Optional Bark push reminders.
- Local-first persistence with no account required.

## Use Cases

Countdown is useful for tracking:

- subscription renewals
- domain and certificate expiry dates
- warranty and insurance deadlines
- membership renewals
- personal deadlines
- recurring reminders
- items that should not be forgotten before they expire

## Features

- Add, edit, archive, restore, and delete countdown items.
- Enter an expiry date directly or by remaining days.
- Add notes, categories, and links.
- Set custom reminder offsets per item.
- Set repeat rules and renew recurring countdown items.
- Search by name, note, category, or link.
- Filter by active, all, 30-day, overdue, or archived items.
- Compact card layout with color-coded ring progress.
- Manual drag ordering with arrange mode.
- One-click ordering by nearest or farthest expiry date.
- Native light and dark mode support.
- Language switcher with 10 app languages.
- Optional Bark push reminders.
- Menu bar entry with nearest due items and quick actions.
- Optional launch at login.
- Local-first storage for core usage.

## Download

Download the latest app bundle from the [Releases](https://github.com/WhiteBalance2800K/countdown/releases) page.

1. Download `Countdown-v0.8-macOS.zip`.
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
dist/Countdown-v0.8-macOS.zip
```

## Bark Push Setup

1. Install Bark on your iPhone and copy your Bark push URL.
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

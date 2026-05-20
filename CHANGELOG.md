# Changelog

All notable changes to Countdown are documented in this file.

## v0.9.4

- Fixed the Settings language row so the visible label is always `Language` and the appearance controls use normal compact sizing.
- Made the main dashboard immersive-mode button explicit with both icon and text.
- Improved immersive-mode hover help to show the item name and remaining days.
- Made the transparent immersive-mode window movable by dragging its background.

## v0.9.3

- Fixed custom Bark reminders so every selected reminder day can be removed, including custom days.
- Allowed per-item Bark reminder lists to be empty.
- Combined Language and Appearance into a single compact Settings row.
- Added immersive mode with transparent window presentation, ring-only content, hover item names, and a visible exit control.
- Added smooth spring transitions and animated window resizing when entering or leaving immersive mode.

## v0.9.2

- Added manual appearance selection for system, light, and dark modes.
- Added an always-on-top pin button beside the dashboard status and category filters.
- Added a system sound preview to the custom Bark reminder row.
- Changed the custom Bark reminder add control to an icon-only plus button.
- Updated the README dashboard screenshot to the new light-mode image.

## v0.9.1

- Replaced the Bark custom reminder calendar picker with plus, minus, and number input controls.
- Removed the link field from the item editor card while preserving existing stored link data.
- Simplified the bottom dashboard controls to icon-only buttons with hover help.
- Kept the Settings language row label as "Language" for every selected app language.
- Added Settings buttons for the GitHub repository and feedback issue page.
- Made the GitHub default README Chinese and moved the English README to `README.en.md`.

## v0.9

- Removed the dashboard search field.
- Added a top dashboard category filter next to the status filter.
- Redesigned category editing with presets, existing categories, and custom category input.
- Replaced raw comma-separated Bark reminder offsets with quick reminder choices and a calendar-date picker.
- Cleaned up dashboard, editor, and settings language for the updated reminder and category flows.

## v0.8

- Added category and link fields for each countdown item.
- Added archive and restore support so completed items can be hidden without deletion.
- Added repeat rules: monthly, quarterly, yearly, and custom day intervals.
- Added search across name, note, category, and link.
- Added dashboard filters for active, all, 30-day, overdue, and archived items.
- Added store helpers for archive, restore, and one-click renewal.
- Updated the item editor to manage category, link, repeat rule, archive state, notes, and reminder offsets together.

## v0.7

- Fixed manual card rearranging so an item near the top can be dragged to the end.
- Removed the heavy translucent drag shadow and replaced it with a subtle outline feedback.
- Kept the smooth spring movement for neighboring cards while dragging.

## v0.6

- Added notes for countdown items.
- Added per-item custom reminder offsets, such as `30, 7, 1, 0` days before expiry.
- Fixed editing overdue items so their original expiry date is not accidentally reset to today.
- Added nearest due items to the macOS menu bar menu.
- Added Settings shortcuts for opening the data folder and backup folder in Finder.

## v0.5

- Made card rearranging substantially smoother with spring layout animation.
- Reduced reorder-mode overhead by saving the new order once when the drag is dropped.
- Replaced constant card jiggle with a calmer drag lift interaction.

## v0.4

- Added automatic backups for countdown data and a recovery prompt when `items.json` is damaged.
- Added a macOS menu bar entry for opening Countdown, adding an item, opening settings, and quitting.
- Added a Launch at Login option in Settings.
- Built and attached a compressed `.app` bundle for the GitHub Release.

## v0.3

- Split the documentation into separate English and Simplified Chinese README pages.
- Kept English as the default GitHub README.
- Adjusted the screenshots section so the two images are displayed side by side at half width.
- Updated release metadata for `v0.3`.

## v0.2

- Added a language switcher in Settings.
- Added 10 app languages: Simplified Chinese, English, Spanish, Hindi, Arabic, French, Bengali, Portuguese, Russian, and Japanese.
- Localized the main dashboard, add/edit dialog, settings dialog, date display, and Bark push text.
- Connected the selected language to native date formatting and the macOS date picker locale.
- Kept all localization preferences local through `UserDefaults`.

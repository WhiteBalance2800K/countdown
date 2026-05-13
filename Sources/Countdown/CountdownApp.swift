import AppKit
import SwiftUI

@main
struct CountdownApp: App {
    @StateObject private var store = ItemsStore()
    @StateObject private var commandCenter = AppCommandCenter()
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    var body: some Scene {
        Window("Countdown", id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(commandCenter)
                .environment(\.locale, Locale(identifier: language.localeIdentifier))
        }
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("Countdown", systemImage: "calendar.badge.clock") {
            CountdownMenuBarView()
                .environmentObject(store)
                .environmentObject(commandCenter)
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct CountdownMenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var store: ItemsStore
    @EnvironmentObject private var commandCenter: AppCommandCenter
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    private var nearestItems: [(item: CountdownItem, days: Int)] {
        let now = Date()
        return store.items
            .map { ($0, $0.remainingDays(on: now)) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.name.localizedCaseInsensitiveCompare(rhs.0.name) == .orderedAscending
                }
                return lhs.1 < rhs.1
            }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        Button {
            openMainWindow()
        } label: {
            Label(L10n.text("openCountdown", language), systemImage: "macwindow")
        }

        Button {
            openMainWindow()
            commandCenter.requestAddItem()
        } label: {
            Label(L10n.text("addHelp", language), systemImage: "plus")
        }

        Button {
            openMainWindow()
            commandCenter.requestSettings()
        } label: {
            Label(L10n.text("settings", language), systemImage: "gearshape")
        }

        Divider()

        Text(String(format: L10n.text("menuItemCount", language), store.items.count))

        if !nearestItems.isEmpty {
            Divider()
            Text(menuNearestTitle)

            ForEach(nearestItems, id: \.item.id) { entry in
                Button {
                    openMainWindow()
                } label: {
                    Label(menuLine(for: entry.item, days: entry.days), systemImage: menuIcon(days: entry.days))
                }
            }
        }

        Divider()

        Button {
            NSApp.terminate(nil)
        } label: {
            Label(L10n.text("quitCountdown", language), systemImage: "power")
        }
    }

    private var menuNearestTitle: String {
        switch language {
        case .simplifiedChinese:
            return "最近到期"
        default:
            return "Nearest due"
        }
    }

    private func menuLine(for item: CountdownItem, days: Int) -> String {
        let dayText: String
        if days < 0 {
            dayText = language == .simplifiedChinese ? "已过期 \(abs(days)) 天" : "overdue by \(abs(days))d"
        } else if days == 0 {
            dayText = L10n.text("today", language)
        } else {
            dayText = L10n.daysValue(days, language)
        }
        return "\(item.name) · \(dayText)"
    }

    private func menuIcon(days: Int) -> String {
        if days < 0 { return "exclamationmark.circle.fill" }
        if days <= 7 { return "bell.badge.fill" }
        return "calendar"
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

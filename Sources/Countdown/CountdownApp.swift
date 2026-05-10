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

        Divider()

        Button {
            NSApp.terminate(nil)
        } label: {
            Label(L10n.text("quitCountdown", language), systemImage: "power")
        }
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

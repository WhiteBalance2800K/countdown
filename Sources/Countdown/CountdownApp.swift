import SwiftUI

@main
struct CountdownApp: App {
    @StateObject private var store = ItemsStore()
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, Locale(identifier: language.localeIdentifier))
        }
        .windowStyle(.hiddenTitleBar)
    }
}

import SwiftUI

@main
struct CountdownApp: App {
    @StateObject private var store = ItemsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

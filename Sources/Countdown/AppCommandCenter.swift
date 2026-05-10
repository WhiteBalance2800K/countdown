import Foundation

@MainActor
final class AppCommandCenter: ObservableObject {
    @Published var addRequestID = UUID()
    @Published var settingsRequestID = UUID()

    func requestAddItem() {
        addRequestID = UUID()
    }

    func requestSettings() {
        settingsRequestID = UUID()
    }
}

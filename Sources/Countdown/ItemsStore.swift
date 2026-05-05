import Foundation

@MainActor
final class ItemsStore: ObservableObject {
    @Published private(set) var items: [CountdownItem] = []

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init() {
        loadFromDisk()
    }

    func add(name: String, expiryDate: Date) {
        let item = CountdownItem(name: name.trimmingCharacters(in: .whitespacesAndNewlines), expiryDate: expiryDate)
            .normalizedExpiryDate()
        items.append(item)
        saveToDisk()
    }

    func update(_ item: CountdownItem) {
        let normalized = item
            .normalizedExpiryDate()
        guard let idx = items.firstIndex(where: { $0.id == normalized.id }) else { return }
        items[idx] = normalized
        saveToDisk()
    }

    func remove(_ item: CountdownItem) {
        items.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func moveItem(id: UUID, before targetID: UUID) {
        guard id != targetID else { return }
        guard let fromIndex = items.firstIndex(where: { $0.id == id }) else { return }
        guard let toIndex = items.firstIndex(where: { $0.id == targetID }) else { return }

        let moving = items.remove(at: fromIndex)
        let insertIndex = fromIndex < toIndex ? max(toIndex - 1, 0) : toIndex
        items.insert(moving, at: insertIndex)
        saveToDisk()
    }

    func sortByRemainingDays(on date: Date, ascending: Bool) {
        items.sort { a, b in
            let da = a.remainingDays(on: date)
            let db = b.remainingDays(on: date)

            if da == db {
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }

            return ascending ? da < db : da > db
        }
        saveToDisk()
    }

    func upsert(_ item: CountdownItem) {
        if items.contains(where: { $0.id == item.id }) {
            update(item)
        } else {
            items.append(item.normalizedExpiryDate())
            saveToDisk()
        }
    }

    private func appSupportDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Countdown", isDirectory: true)
    }

    private func dataFileURL() -> URL {
        appSupportDir().appendingPathComponent("items.json", isDirectory: false)
    }

    private func ensureDirExists() {
        let dir = appSupportDir()
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            // If we can't create the folder, persistence will fail; keep running in-memory.
        }
    }

    private func loadFromDisk() {
        ensureDirExists()
        let url = dataFileURL()

        guard FileManager.default.fileExists(atPath: url.path) else {
            items = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            items = try decoder.decode([CountdownItem].self, from: data)
        } catch {
            // Keep a usable app even if the file is corrupted.
            items = []
        }
    }

    private func saveToDisk() {
        ensureDirExists()
        let url = dataFileURL()

        do {
            let data = try encoder.encode(items)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Ignore save errors; user can keep using the app.
        }
    }
}

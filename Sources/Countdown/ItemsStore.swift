import Foundation

@MainActor
final class ItemsStore: ObservableObject {
    @Published private(set) var items: [CountdownItem] = []
    @Published var recoveryNotice: DataRecoveryNotice?

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

    func add(
        name: String,
        expiryDate: Date,
        note: String = "",
        reminderOffsets: [Int] = CountdownItem.defaultReminderOffsets,
        category: String = "",
        link: String = "",
        isArchived: Bool = false,
        repeatRule: RepeatRule = .none,
        repeatCustomDays: Int = 30
    ) {
        let item = CountdownItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            expiryDate: expiryDate,
            note: note,
            reminderOffsets: reminderOffsets,
            category: category,
            link: link,
            isArchived: isArchived,
            repeatRule: repeatRule,
            repeatCustomDays: repeatCustomDays
        )
        .normalizedExpiryDate()
        items.append(item)
        saveToDisk()
    }

    func update(_ item: CountdownItem) {
        let normalized = item.normalizedExpiryDate()
        guard let idx = items.firstIndex(where: { $0.id == normalized.id }) else { return }
        items[idx] = normalized
        saveToDisk()
    }

    func remove(_ item: CountdownItem) {
        items.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func archive(_ item: CountdownItem) {
        var copy = item
        copy.isArchived = true
        copy.updatedAt = Date()
        update(copy)
    }

    func restore(_ item: CountdownItem) {
        var copy = item
        copy.isArchived = false
        copy.updatedAt = Date()
        update(copy)
    }

    func renew(_ item: CountdownItem) {
        guard let renewed = item.nextRenewedItem() else { return }
        update(renewed)
    }

    func moveItem(id: UUID, before targetID: UUID, persistsImmediately: Bool = true) {
        guard id != targetID else { return }
        guard let fromIndex = items.firstIndex(where: { $0.id == id }) else { return }
        guard let toIndex = items.firstIndex(where: { $0.id == targetID }) else { return }
        guard fromIndex != toIndex, fromIndex + 1 != toIndex else { return }

        moveItem(id: id, to: toIndex, persistsImmediately: persistsImmediately)
    }

    func moveItem(id: UUID, after targetID: UUID, persistsImmediately: Bool = true) {
        guard id != targetID else { return }
        guard let fromIndex = items.firstIndex(where: { $0.id == id }) else { return }
        guard let toIndex = items.firstIndex(where: { $0.id == targetID }) else { return }
        guard fromIndex != toIndex, fromIndex != toIndex + 1 else { return }

        moveItem(id: id, to: toIndex + 1, persistsImmediately: persistsImmediately)
    }

    func moveItemToEnd(id: UUID, persistsImmediately: Bool = true) {
        guard let fromIndex = items.firstIndex(where: { $0.id == id }) else { return }
        guard fromIndex != items.index(before: items.endIndex) else { return }

        moveItem(id: id, to: items.endIndex, persistsImmediately: persistsImmediately)
    }

    private func moveItem(id: UUID, to destinationIndex: Int, persistsImmediately: Bool) {
        guard let fromIndex = items.firstIndex(where: { $0.id == id }) else { return }
        let boundedDestination = min(max(destinationIndex, items.startIndex), items.endIndex)
        var insertIndex = boundedDestination
        if fromIndex < boundedDestination {
            insertIndex -= 1
        }

        let moving = items.remove(at: fromIndex)
        items.insert(moving, at: insertIndex)
        if persistsImmediately {
            saveToDisk()
        }
    }

    func saveCurrentOrder() {
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

    func exportData(format: CountdownDataFileFormat) throws -> Data {
        switch format {
        case .json:
            return try encoder.encode(items)
        case .csv:
            return Self.csvData(for: items)
        }
    }

    func importData(from url: URL, format: CountdownDataFileFormat) throws -> Int {
        let importedItems: [CountdownItem]

        switch format {
        case .json:
            let data = try Data(contentsOf: url)
            importedItems = try decoder.decode([CountdownItem].self, from: data)
        case .csv:
            let text = try String(contentsOf: url, encoding: .utf8)
            importedItems = try Self.items(fromCSV: text)
        }

        for item in importedItems {
            let normalized = item.normalizedExpiryDate()
            if let index = items.firstIndex(where: { $0.id == normalized.id }) {
                items[index] = normalized
            } else {
                items.append(normalized)
            }
        }

        saveToDisk()
        return importedItems.count
    }

    func appSupportDirectoryURL() -> URL {
        ensureDirExists()
        return appSupportDir()
    }

    func backupsDirectoryURL() -> URL {
        ensureBackupsDirExists()
        return backupsDir()
    }

    private func appSupportDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Countdown", isDirectory: true)
    }

    private func dataFileURL() -> URL {
        appSupportDir().appendingPathComponent("items.json", isDirectory: false)
    }

    private func backupsDir() -> URL {
        appSupportDir().appendingPathComponent("backups", isDirectory: true)
    }

    private func ensureDirExists() {
        let dir = appSupportDir()
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            // If we can't create the folder, persistence will fail; keep running in-memory.
        }
    }

    private func ensureBackupsDirExists() {
        do {
            try FileManager.default.createDirectory(at: backupsDir(), withIntermediateDirectories: true)
        } catch {
            // Backups are best-effort; persistence should continue without them.
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
            recoverFromCorruptedDataFile(at: url)
        }
    }

    private func saveToDisk() {
        ensureDirExists()
        let url = dataFileURL()

        do {
            let data = try encoder.encode(items)
            try data.write(to: url, options: [.atomic])
            saveSnapshotBackup(data)
        } catch {
            // Ignore save errors; user can keep using the app.
        }
    }

    private func recoverFromCorruptedDataFile(at url: URL) {
        let corruptedBackupURL = backupCorruptedDataFile(at: url)

        if let recovered = latestValidSnapshot() {
            items = recovered.items
            do {
                let data = try encoder.encode(recovered.items)
                try data.write(to: url, options: [.atomic])
            } catch {
                // The in-memory recovery still lets the app stay usable.
            }
            recoveryNotice = .restored(corruptedBackupURL: corruptedBackupURL, restoredFromURL: recovered.url)
            return
        }

        items = []
        recoveryNotice = .manualRecoveryNeeded(corruptedBackupURL: corruptedBackupURL)
    }

    private func backupCorruptedDataFile(at url: URL) -> URL? {
        ensureBackupsDirExists()
        let destination = backupsDir().appendingPathComponent("items-corrupt-\(Self.timestamp()).json")

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    private func saveSnapshotBackup(_ data: Data) {
        ensureBackupsDirExists()
        let destination = backupsDir().appendingPathComponent("items-backup-\(Self.timestamp()).json")

        do {
            try data.write(to: destination, options: [.atomic])
            pruneSnapshotBackups(keeping: 12)
        } catch {
            // Snapshot backup failure should not block the primary save.
        }
    }

    private func latestValidSnapshot() -> (items: [CountdownItem], url: URL)? {
        let snapshots = snapshotBackupURLs()

        for url in snapshots {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try decoder.decode([CountdownItem].self, from: data)
                return (decoded, url)
            } catch {
                continue
            }
        }

        return nil
    }

    private func pruneSnapshotBackups(keeping limit: Int) {
        let snapshots = snapshotBackupURLs()
        guard snapshots.count > limit else { return }

        for url in snapshots.dropFirst(limit) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func snapshotBackupURLs() -> [URL] {
        let dir = backupsDir()
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { $0.lastPathComponent.hasPrefix("items-backup-") && $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return leftDate > rightDate
            }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private static let csvColumns = [
        "id",
        "name",
        "expiryDate",
        "createdAt",
        "updatedAt",
        "note",
        "reminderOffsets",
        "category",
        "link",
        "isArchived",
        "repeatRule",
        "repeatCustomDays",
    ]

    private static func csvData(for items: [CountdownItem]) -> Data {
        let formatter = ISO8601DateFormatter()
        let rows = items.map { item in
            [
                item.id.uuidString,
                item.name,
                formatter.string(from: item.expiryDate),
                formatter.string(from: item.createdAt),
                formatter.string(from: item.updatedAt),
                item.note,
                item.reminderOffsets.map(String.init).joined(separator: ";"),
                item.category,
                item.link,
                item.isArchived ? "true" : "false",
                item.repeatRule.rawValue,
                "\(item.repeatCustomDays)",
            ].map(Self.csvEscaped)
                .joined(separator: ",")
        }

        let csv = ([csvColumns.joined(separator: ",")] + rows).joined(separator: "\n") + "\n"
        return Data(csv.utf8)
    }

    private static func items(fromCSV text: String) throws -> [CountdownItem] {
        let rows = parseCSV(text)
            .filter { row in
                row.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
        guard let header = rows.first else { return [] }

        let keys = header.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let dataRows = rows.dropFirst()

        return try dataRows.enumerated().map { offset, row in
            func value(_ key: String) -> String {
                guard let index = keys.firstIndex(of: key), index < row.count else { return "" }
                return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let name = value("name")
            guard !name.isEmpty, let expiryDate = parseDate(value("expiryDate")) else {
                throw CountdownDataTransferError.invalidCSVRow(offset + 2)
            }

            let id = UUID(uuidString: value("id")) ?? UUID()
            let createdAt = parseDate(value("createdAt")) ?? Date()
            let updatedAt = parseDate(value("updatedAt")) ?? Date()
            let reminderOffsets = value("reminderOffsets")
                .split(separator: ";")
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            let repeatRule = RepeatRule(rawValue: value("repeatRule")) ?? .none
            let repeatCustomDays = Int(value("repeatCustomDays")) ?? 30

            return CountdownItem(
                id: id,
                name: name,
                expiryDate: expiryDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                note: value("note"),
                reminderOffsets: reminderOffsets,
                category: value("category"),
                link: value("link"),
                isArchived: parseBool(value("isArchived")),
                repeatRule: repeatRule,
                repeatCustomDays: repeatCustomDays
            )
        }
    }

    private static func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains("\r") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private static func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if isQuoted {
                if character == "\"" {
                    let nextIndex = text.index(after: index)
                    if nextIndex < text.endIndex, text[nextIndex] == "\"" {
                        field.append("\"")
                        index = nextIndex
                    } else {
                        isQuoted = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    isQuoted = true
                case ",":
                    row.append(field)
                    field = ""
                case "\n":
                    row.append(field)
                    rows.append(row)
                    row = []
                    field = ""
                case "\r":
                    break
                default:
                    field.append(character)
                }
            }

            index = text.index(after: index)
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private static func parseDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current

        for format in ["yyyy-MM-dd", "yyyy/M/d", "yyyy年M月d日"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }

    private static func parseBool(_ value: String) -> Bool {
        let normalized = value.lowercased()
        return normalized == "true" || normalized == "1" || normalized == "yes"
    }
}

enum CountdownDataFileFormat: String {
    case json
    case csv

    var fileExtension: String { rawValue }
}

enum CountdownDataTransferError: LocalizedError {
    case invalidCSVRow(Int)

    var errorDescription: String? {
        switch self {
        case .invalidCSVRow(let row):
            return "Invalid CSV row: \(row)"
        }
    }
}

struct DataRecoveryNotice: Identifiable, Equatable {
    enum Kind: Equatable {
        case restored(restoredFromURL: URL?)
        case manualRecoveryNeeded
    }

    let id = UUID()
    let kind: Kind
    let corruptedBackupURL: URL?

    static func restored(corruptedBackupURL: URL?, restoredFromURL: URL?) -> DataRecoveryNotice {
        DataRecoveryNotice(kind: .restored(restoredFromURL: restoredFromURL), corruptedBackupURL: corruptedBackupURL)
    }

    static func manualRecoveryNeeded(corruptedBackupURL: URL?) -> DataRecoveryNotice {
        DataRecoveryNotice(kind: .manualRecoveryNeeded, corruptedBackupURL: corruptedBackupURL)
    }
}

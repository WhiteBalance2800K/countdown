import Foundation

struct CountdownItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var expiryDate: Date
    var createdAt: Date
    var updatedAt: Date
    var note: String
    var reminderOffsets: [Int]

    init(
        id: UUID = UUID(),
        name: String,
        expiryDate: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        note: String = "",
        reminderOffsets: [Int] = Self.defaultReminderOffsets
    ) {
        self.id = id
        self.name = name
        self.expiryDate = expiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.note = note
        self.reminderOffsets = Self.normalizedReminderOffsets(reminderOffsets)
    }

    func remainingDays(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func normalizedExpiryDate(calendar: Calendar = .current) -> CountdownItem {
        var copy = self
        copy.expiryDate = calendar.startOfDay(for: expiryDate)
        copy.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.reminderOffsets = Self.normalizedReminderOffsets(reminderOffsets)
        copy.updatedAt = Date()
        return copy
    }

    static let defaultReminderOffsets = [7, 0]

    static func normalizedReminderOffsets(_ offsets: [Int]) -> [Int] {
        let normalized = Set(offsets.map { min(max($0, 0), 3650) })
        let sorted = normalized.sorted(by: >)
        return sorted.isEmpty ? defaultReminderOffsets : sorted
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case expiryDate
        case createdAt
        case updatedAt
        case note
        case reminderOffsets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        expiryDate = try container.decode(Date.self, forKey: .expiryDate)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        reminderOffsets = Self.normalizedReminderOffsets(
            try container.decodeIfPresent([Int].self, forKey: .reminderOffsets) ?? Self.defaultReminderOffsets
        )
    }
}

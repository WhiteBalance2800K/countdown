import Foundation

enum RepeatRule: String, CaseIterable, Codable, Equatable, Identifiable {
    case none
    case monthly
    case quarterly
    case yearly
    case customDays

    var id: String { rawValue }

    func nextDate(after date: Date, calendar: Calendar = .current, customDays: Int = 30) -> Date? {
        let base = calendar.startOfDay(for: date)
        switch self {
        case .none:
            return nil
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: base)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: base)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: base)
        case .customDays:
            return calendar.date(byAdding: .day, value: max(customDays, 1), to: base)
        }
    }
}

struct CountdownItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var expiryDate: Date
    var createdAt: Date
    var updatedAt: Date
    var note: String
    var reminderOffsets: [Int]
    var category: String
    var link: String
    var isArchived: Bool
    var repeatRule: RepeatRule
    var repeatCustomDays: Int

    init(
        id: UUID = UUID(),
        name: String,
        expiryDate: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        note: String = "",
        reminderOffsets: [Int] = Self.defaultReminderOffsets,
        category: String = "",
        link: String = "",
        isArchived: Bool = false,
        repeatRule: RepeatRule = .none,
        repeatCustomDays: Int = 30
    ) {
        self.id = id
        self.name = name
        self.expiryDate = expiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.note = note
        self.reminderOffsets = Self.normalizedReminderOffsets(reminderOffsets)
        self.category = category
        self.link = link
        self.isArchived = isArchived
        self.repeatRule = repeatRule
        self.repeatCustomDays = max(repeatCustomDays, 1)
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
        copy.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.link = link.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.repeatCustomDays = max(repeatCustomDays, 1)
        copy.reminderOffsets = Self.normalizedReminderOffsets(reminderOffsets)
        copy.updatedAt = Date()
        return copy
    }

    func matchesSearch(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        return name.localizedCaseInsensitiveContains(q)
            || note.localizedCaseInsensitiveContains(q)
            || category.localizedCaseInsensitiveContains(q)
            || link.localizedCaseInsensitiveContains(q)
    }

    func nextRenewedItem(from date: Date = Date(), calendar: Calendar = .current) -> CountdownItem? {
        guard let next = repeatRule.nextDate(after: max(expiryDate, date), calendar: calendar, customDays: repeatCustomDays) else {
            return nil
        }
        var copy = self
        copy.expiryDate = calendar.startOfDay(for: next)
        copy.isArchived = false
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
        case category
        case link
        case isArchived
        case repeatRule
        case repeatCustomDays
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
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        link = try container.decodeIfPresent(String.self, forKey: .link) ?? ""
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        repeatRule = try container.decodeIfPresent(RepeatRule.self, forKey: .repeatRule) ?? .none
        repeatCustomDays = max(try container.decodeIfPresent(Int.self, forKey: .repeatCustomDays) ?? 30, 1)
    }
}

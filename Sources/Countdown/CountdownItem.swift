import Foundation

struct CountdownItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var expiryDate: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        expiryDate: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.expiryDate = expiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func remainingDays(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func normalizedExpiryDate(calendar: Calendar = .current) -> CountdownItem {
        var copy = self
        copy.expiryDate = calendar.startOfDay(for: expiryDate)
        copy.updatedAt = Date()
        return copy
    }
}

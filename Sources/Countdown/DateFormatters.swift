import Foundation

enum DateFormatters {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        // Fixed-format for display: 2026年3月15日
        f.locale = Locale(identifier: "zh_CN")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy年M月d日"
        return f
    }()
}

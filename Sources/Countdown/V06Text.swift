import Foundation

enum V06Text {
    static func text(_ key: String, _ language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            return zh[key] ?? en[key] ?? key
        default:
            return en[key] ?? key
        }
    }

    private static let zh: [String: String] = [
        "note": "备注",
        "customReminderOffsets": "自定义提醒天数",
        "customReminderOffsetsHelp": "将使用这些提醒天数：%@。用逗号或空格分隔。",
        "data": "数据",
        "openDataFolder": "打开数据文件夹",
        "openBackupFolder": "打开备份文件夹",
    ]

    private static let en: [String: String] = [
        "note": "Note",
        "customReminderOffsets": "Custom reminder days",
        "customReminderOffsetsHelp": "Reminder days in use: %@. Separate values with commas or spaces.",
        "data": "Data",
        "openDataFolder": "Open Data Folder",
        "openBackupFolder": "Open Backup Folder",
    ]
}

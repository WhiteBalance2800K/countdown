import SwiftUI

struct ItemCardView: View {
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

    let item: CountdownItem
    let now: Date
    let onEdit: () -> Void
    let onArchive: () -> Void

    private var remainingDays: Int { item.remainingDays(on: now) }

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    private var ringColor: Color {
        let d = remainingDays
        if d >= 30 { return .green }
        if d >= 7 { return .orange }
        return .red
    }

    private var progress: Double {
        let maxDays = 30.0
        let d = Double(remainingDays)
        return min(max(d / maxDays, 0), 1)
    }

    var body: some View {
        Button {
            onEdit()
        } label: {
            HStack(spacing: 14) {
                RingView(progress: progress, color: ringColor) {
                    VStack(spacing: 2) {
                        Text(displayNumber)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                        Text(remainingDays < 0 ? L10n.text("filterOverdue", language) : L10n.text("daysMode", language))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(L10n.text("due", language)): \(DateFormatters.shortDateString(from: item.expiryDate, language: language))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(L10n.text("edit", language)) { onEdit() }
            Button(L10n.text("archive", language)) { onArchive() }
        }
    }

    private var displayNumber: String {
        remainingDays < 0 ? "0" : "\(remainingDays)"
    }
}

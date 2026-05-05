import SwiftUI

struct ItemCardView: View {
    let item: CountdownItem
    let now: Date
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var remainingDays: Int { item.remainingDays(on: now) }

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
                        Text("\(abs(remainingDays))")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                        Text(remainingDays < 0 ? "已过期" : "天")
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

                    Text("到期: \(DateFormatters.shortDate.string(from: item.expiryDate))")
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
            Button("编辑") { onEdit() }
            Button("删除", role: .destructive) { onDelete() }
        }
    }
}

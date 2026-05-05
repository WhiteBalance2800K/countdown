import SwiftUI
import UniformTypeIdentifiers

enum UrgencyBand {
    case urgent
    case warning
    case later

    init(days: Int) {
        if days < 15 {
            self = .urgent
        } else if days <= 30 {
            self = .warning
        } else {
            self = .later
        }
    }

    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .urgent:
            return RadixPalette.dangerSolid(scheme)
        case .warning:
            return RadixPalette.warningSolid(scheme)
        case .later:
            return RadixPalette.successSolid(scheme)
        }
    }

    func tint(_ scheme: ColorScheme) -> Color {
        switch self {
        case .urgent:
            return RadixPalette.dangerElement(scheme)
        case .warning:
            return RadixPalette.warningElement(scheme)
        case .later:
            return RadixPalette.successElement(scheme)
        }
    }
}

struct DashboardStats {
    let total: Int
    let overdue: Int
    let within7Days: Int
    let within30Days: Int
    let nextItem: CountdownItem?
    let nextItemDays: Int?

    init(items: [CountdownItem], now: Date) {
        total = items.count

        var overdue = 0
        var within7Days = 0
        var within30Days = 0
        var nearest: (item: CountdownItem, days: Int)?

        for item in items {
            let days = item.remainingDays(on: now)
            if days < 0 {
                overdue += 1
            }
            if (0...7).contains(days) {
                within7Days += 1
            }
            if (0...30).contains(days) {
                within30Days += 1
            }

            if let current = nearest {
                let currentDistance = abs(current.days)
                let newDistance = abs(days)
                if newDistance < currentDistance || (newDistance == currentDistance && days < current.days) {
                    nearest = (item, days)
                }
            } else {
                nearest = (item, days)
            }
        }

        self.overdue = overdue
        self.within7Days = within7Days
        self.within30Days = within30Days
        nextItem = nearest?.item
        nextItemDays = nearest?.days
    }
}

struct SoftDashboardView: View {
    let items: [CountdownItem]
    let now: Date
    let isManualOrder: Bool
    let store: ItemsStore
    @Binding var draggingItemID: UUID?
    let onEdit: (CountdownItem) -> Void
    let onDelete: (CountdownItem) -> Void

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 560
            let columns = Array(
                repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 14),
                count: isCompact ? 1 : 2
            )

            ScrollView {
                if items.isEmpty {
                    EmptySoftDashboardView()
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(items) { item in
                            SoftMetricCard(
                                item: item,
                                now: now,
                                showsDragHandle: isManualOrder,
                                onEdit: { onEdit(item) },
                                onDelete: { onDelete(item) }
                            )
                            .modifier(ManualReorderModifier(
                                enabled: isManualOrder,
                                item: item,
                                store: store,
                                draggingItemID: $draggingItemID
                            ))
                        }
                    }
                    .frame(maxWidth: isCompact ? 330 : 520, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, isCompact ? 20 : 22)
                    .padding(.top, 24)
                    .padding(.bottom, 104)
                }
            }
        }
    }
}

private struct SoftMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: CountdownItem
    let now: Date
    let showsDragHandle: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var isJiggling = false

    private var remainingDays: Int {
        item.remainingDays(on: now)
    }

    private var urgency: UrgencyBand {
        UrgencyBand(days: remainingDays)
    }

    private var progress: Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: item.createdAt)
        let end = calendar.startOfDay(for: item.expiryDate)
        let today = calendar.startOfDay(for: now)
        let totalDays = max(calendar.dateComponents([.day], from: start, to: end).day ?? 1, 1)
        let remaining = max(calendar.dateComponents([.day], from: today, to: end).day ?? 0, 0)
        return min(max(Double(remaining) / Double(totalDays), 0), 1)
    }

    var body: some View {
        Button {
            onEdit()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 9) {
                    if showsDragHandle {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(tertiaryText)
                            .frame(width: 12)
                    }

                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RadixPalette.accentSolid(colorScheme))
                        .frame(width: 20, height: 20)

                    Text(item.name)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)

                    Spacer(minLength: 8)
                }

                Spacer(minLength: 16)

                HStack(alignment: .bottom, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(primaryNumber)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                    }

                    Spacer(minLength: 4)

                    RingView(
                        progress: progress,
                        color: urgency.color(colorScheme),
                        lineWidth: 7,
                        trackColor: ringTrackColor
                    ) {
                        EmptyView()
                    }
                    .frame(width: 46, height: 46)
                    .overlay {
                        if isHovering {
                            RingParticleEffect(color: urgency.color(colorScheme))
                                .frame(width: 62, height: 62)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeOut(duration: 0.18), value: isHovering)
                }

                Text(DateFormatters.shortDate.string(from: item.expiryDate))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
                    .padding(.top, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardFill)
                    .shadow(color: bottomShadowColor, radius: isHovering ? 14 : 8, x: 0, y: isHovering ? 8 : 4)
                    .shadow(color: bottomShadowColor, radius: isHovering ? 18 : 13, x: 0, y: isHovering ? 11 : 8)
            )
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("编辑")

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("删除")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(secondaryText)
                .padding(10)
                .opacity(isHovering ? 1 : 0)
                .animation(.easeOut(duration: 0.14), value: isHovering)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(hoverStrokeColor, lineWidth: 1)
            }
            .rotationEffect(.degrees(jiggleAngle))
            .offset(x: jiggleOffsetX, y: isHovering ? -3 : 0)
            .animation(
                showsDragHandle ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true) : .default,
                value: isJiggling
            )
            .scaleEffect(cardScale)
            .animation(.spring(response: 0.26, dampingFraction: 0.78), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            if showsDragHandle {
                isJiggling = true
            }
        }
        .onChange(of: showsDragHandle) { newValue in
            isJiggling = false
            if newValue {
                DispatchQueue.main.async {
                    isJiggling = true
                }
            }
        }
    }

    private var jiggleAngle: Double {
        guard showsDragHandle else { return 0 }
        let sign = item.id.uuidString.hashValue.isMultiple(of: 2) ? 1.0 : -1.0
        return (isJiggling ? 0.62 : -0.62) * sign
    }

    private var jiggleOffsetX: CGFloat {
        guard showsDragHandle else { return 0 }
        return isJiggling ? 0.45 : -0.45
    }

    private var cardScale: CGFloat {
        if showsDragHandle {
            return isJiggling ? 1.004 : 0.998
        }
        return isHovering ? 1.022 : 1
    }

    private var cardFill: some ShapeStyle {
        LinearGradient(
            colors: cardFillColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardFillColors: [Color] {
        return [
            isHovering ? RadixPalette.hoverBackground(colorScheme) : RadixPalette.subtleBackground(colorScheme),
            urgency.tint(colorScheme).opacity(colorScheme == .dark ? 0.34 : 0.50),
        ]
    }

    private var primaryText: Color {
        RadixPalette.text(colorScheme)
    }

    private var secondaryText: Color {
        RadixPalette.faintText(colorScheme)
    }

    private var tertiaryText: Color {
        RadixPalette.mutedText(colorScheme).opacity(0.70)
    }

    private var ringTrackColor: Color {
        RadixPalette.border(colorScheme).opacity(0.78)
    }

    private var bottomShadowColor: Color {
        colorScheme == .dark
            ? .black.opacity(isHovering ? 0.36 : 0.22)
            : .black.opacity(isHovering ? 0.12 : 0.055)
    }

    private var hoverStrokeColor: Color {
        isHovering ? RadixPalette.borderHover(colorScheme) : RadixPalette.border(colorScheme)
    }

    private var iconName: String {
        if remainingDays < 0 {
            return "exclamationmark.circle.fill"
        }
        if remainingDays < 15 {
            return "flame.fill"
        }
        if remainingDays <= 30 {
            return "clock.fill"
        }
        return "calendar.circle.fill"
    }

    private var primaryNumber: String {
        if remainingDays < 0 {
            return "\(abs(remainingDays))"
        }
        return "\(remainingDays)"
    }

}

private struct SoftBottomBar: View {
    @Environment(\.colorScheme) private var colorScheme

    let sortAscending: Bool
    let isManualOrder: Bool
    let onToggleMode: () -> Void
    let onToggleSort: () -> Void
    let onAdd: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                BottomBarButton(
                    title: "卡片",
                    systemImage: "square.grid.2x2.fill",
                    isSelected: true,
                    action: {}
                )

                BottomBarButton(
                    title: isManualOrder ? "完成" : "调整",
                    systemImage: isManualOrder ? "checkmark" : "line.3.horizontal",
                    isSelected: isManualOrder,
                    action: onToggleMode
                )

                BottomBarButton(
                    title: sortAscending ? "临近" : "较远",
                    systemImage: sortAscending ? "arrow.down" : "arrow.up",
                    isSelected: false,
                    action: onToggleSort
                )
                .disabled(isManualOrder)
                .opacity(isManualOrder ? 0.42 : 1)

                BottomBarButton(
                    title: "设置",
                    systemImage: "gearshape.fill",
                    isSelected: false,
                    action: onSettings
                )
            }
            .padding(8)
            .background(
                Capsule(style: .continuous)
                    .fill(barFill)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.32 : 0.08), radius: 14, x: 0, y: 8)
            )

            Button {
                onAdd()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(RadixPalette.text(colorScheme).opacity(0.72))
                    .frame(width: 58, height: 58)
                    .background(
                        Circle()
                            .fill(barFill)
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0.30 : 0.08), radius: 14, x: 0, y: 8)
                    )
            }
            .buttonStyle(.plain)
            .help("新增")
            .keyboardShortcut("n", modifiers: [.command])
        }
    }

    private var barFill: Color {
        RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.94 : 0.98)
    }
}

private struct BottomBarButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : inactiveText)
            .frame(width: 66, height: 48)
            .background(
                Group {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(selectedFill)
                            .shadow(color: Color(red: 1.0, green: 0.35, blue: 0.13).opacity(0.26), radius: 11, x: 0, y: 6)
                    } else {
                        Capsule(style: .continuous)
                            .fill(Color.clear)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var selectedFill: some ShapeStyle {
        LinearGradient(
            colors: [
                RadixPalette.accentSolid(colorScheme),
                RadixPalette.accentSolid(colorScheme).opacity(0.82),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var inactiveText: Color {
        RadixPalette.mutedText(colorScheme)
    }
}

struct FloatingDashboardControls: View {
    let sortAscending: Bool
    let isManualOrder: Bool
    let onToggleMode: () -> Void
    let onToggleSort: () -> Void
    let onAdd: () -> Void
    let onSettings: () -> Void

    var body: some View {
        SoftBottomBar(
            sortAscending: sortAscending,
            isManualOrder: isManualOrder,
            onToggleMode: onToggleMode,
            onToggleSort: onToggleSort,
            onAdd: onAdd,
            onSettings: onSettings
        )
    }
}

struct SoftBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RadixPalette.appBackground(colorScheme)
            .ignoresSafeArea()
    }
}

private struct EmptySoftDashboardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(RadixPalette.accentSolid(colorScheme))

            Text("No items yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(RadixPalette.text(colorScheme))

            Text("Use the plus button to add your first expiry date.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RadixPalette.mutedText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 140)
        .padding(.horizontal, 32)
    }
}

private struct ManualReorderModifier: ViewModifier {
    let enabled: Bool
    let item: CountdownItem
    let store: ItemsStore
    @Binding var draggingItemID: UUID?

    func body(content: Content) -> some View {
        if enabled {
            content
                .onDrag {
                    draggingItemID = item.id
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: ItemReorderDropDelegate(
                        targetItem: item,
                        store: store,
                        draggingItemID: $draggingItemID
                    )
                )
        } else {
            content
        }
    }
}

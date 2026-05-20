import AppKit
import QuartzCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ItemsStore
    @EnvironmentObject private var commandCenter: AppCommandCenter
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("sortAscending") private var sortAscending: Bool = true
    @AppStorage("sortMode") private var sortModeRaw: String = SortMode.remainingDays.rawValue
    @AppStorage("pushEnabled") private var pushEnabled: Bool = false
    @AppStorage("barkPushAddress") private var barkPushAddress: String = "https://api.day.app/"
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue
    @AppStorage("isAlwaysOnTop") private var isAlwaysOnTop: Bool = false
    @AppStorage("isImmersiveMode") private var isImmersiveMode: Bool = false

    @State private var now = Date()
    @State private var isAdding = false
    @State private var isShowingSettings = false
    @State private var isCheckingPushes = false
    @State private var editingItem: CountdownItem?
    @State private var draggingItemID: UUID?
    @State private var filterRaw = DashboardFilter.active.rawValue
    @State private var categoryFilter = Self.allCategoriesFilterValue

    private enum SortMode: String {
        case remainingDays
        case manual
    }

    private enum DashboardFilter: String, CaseIterable, Identifiable {
        case active
        case all
        case within30
        case overdue
        case archived

        var id: String { rawValue }
    }

    private var sortMode: SortMode { SortMode(rawValue: sortModeRaw) ?? .remainingDays }
    private var filter: DashboardFilter { DashboardFilter(rawValue: filterRaw) ?? .active }

    private var categoryOptions: [String] {
        let categories = store.items
            .map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(categories)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var displayItems: [CountdownItem] {
        store.items.filter { item in
            let normalizedCategory = item.category.trimmingCharacters(in: .whitespacesAndNewlines)
            if categoryFilter == Self.uncategorizedFilterValue {
                guard normalizedCategory.isEmpty else { return false }
            } else if categoryFilter != Self.allCategoriesFilterValue {
                guard normalizedCategory == categoryFilter else { return false }
            }

            let days = item.remainingDays(on: now)
            switch filter {
            case .active:
                return !item.isArchived
            case .all:
                return true
            case .within30:
                return !item.isArchived && (0...30).contains(days)
            case .overdue:
                return !item.isArchived && days < 0
            case .archived:
                return item.isArchived
            }
        }
    }

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isImmersiveMode {
                ImmersiveDashboardView(
                    items: displayItems,
                    now: now,
                    onExit: exitImmersiveMode
                )
                .transition(.scale(scale: 0.84).combined(with: .opacity))
            } else {
                normalDashboard
                    .transition(.scale(scale: 1.08).combined(with: .opacity))
            }
        }
        .background(Color.clear)
        .frame(
            minWidth: isImmersiveMode ? 160 : 375,
            idealWidth: isImmersiveMode ? 260 : 760,
            minHeight: isImmersiveMode ? 120 : 500,
            idealHeight: isImmersiveMode ? 280 : 650
        )
        .animation(.interpolatingSpring(stiffness: 170, damping: 22), value: isImmersiveMode)
        .onAppear {
            updateWindowPresentation(animated: false)
            checkAndSendDuePushes()
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                now = Date()
                checkAndSendDuePushes()
            }
        }
        .onReceive(Timer.publish(every: 3600, on: .main, in: .common).autoconnect()) { _ in
            now = Date()
            checkAndSendDuePushes()
        }
        .onReceive(store.$items) { _ in
            checkAndSendDuePushes()
        }
        .onChange(of: commandCenter.addRequestID) { _ in
            isShowingSettings = false
            editingItem = nil
            isAdding = true
        }
        .onChange(of: commandCenter.settingsRequestID) { _ in
            isAdding = false
            editingItem = nil
            isShowingSettings = true
        }
        .onChange(of: pushEnabled) { _ in
            checkAndSendDuePushes()
        }
        .onChange(of: barkPushAddress) { _ in
            checkAndSendDuePushes()
        }
        .onChange(of: isAlwaysOnTop) { _ in
            updateWindowPresentation()
        }
        .onChange(of: isImmersiveMode) { _ in
            updateWindowPresentation()
        }
        .sheet(isPresented: $isAdding) {
            ItemEditorView(mode: .add, initialItem: nil, categorySuggestions: categoryOptions) { result in
                switch result {
                case .cancel:
                    break
                case .save(let name, let expiryDate, let note, let reminderOffsets, let category, let link, let isArchived, let repeatRule, let repeatCustomDays):
                    store.add(
                        name: name,
                        expiryDate: expiryDate,
                        note: note,
                        reminderOffsets: reminderOffsets,
                        category: category,
                        link: link,
                        isArchived: isArchived,
                        repeatRule: repeatRule,
                        repeatCustomDays: repeatCustomDays
                    )
                }

                isAdding = false
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditorView(mode: .edit, initialItem: item, categorySuggestions: categoryOptions) { result in
                switch result {
                case .cancel:
                    break
                case .save(let name, let expiryDate, let note, let reminderOffsets, let category, let link, let isArchived, let repeatRule, let repeatCustomDays):
                    var updated = item
                    updated.name = name
                    updated.expiryDate = expiryDate
                    updated.note = note
                    updated.reminderOffsets = reminderOffsets
                    updated.category = category
                    updated.link = link
                    updated.isArchived = isArchived
                    updated.repeatRule = repeatRule
                    updated.repeatCustomDays = repeatCustomDays
                    updated.updatedAt = Date()
                    store.update(updated)
                }

                editingItem = nil
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            PushSettingsView()
                .environmentObject(store)
        }
        .alert(item: $store.recoveryNotice) { notice in
            recoveryAlert(for: notice)
        }
    }

    private var normalDashboard: some View {
        ZStack(alignment: .bottom) {
            SoftBackground()

            VStack(spacing: 0) {
                dashboardFilterBar
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                SoftDashboardView(
                    items: displayItems,
                    now: now,
                    isManualOrder: sortMode == .manual,
                    store: store,
                    draggingItemID: $draggingItemID,
                    onEdit: { editingItem = $0 },
                    onDelete: { store.remove($0) }
                )
            }

            FloatingDashboardControls(
                sortAscending: sortAscending,
                isManualOrder: sortMode == .manual,
                onToggleMode: toggleSortMode,
                onToggleSort: toggleSortDirection,
                onAdd: { isAdding = true },
                onSettings: { isShowingSettings = true }
            )
            .padding(.bottom, 22)
        }
    }

    private var dashboardFilterBar: some View {
        HStack(spacing: 10) {
            Picker("", selection: $filterRaw) {
                ForEach(DashboardFilter.allCases) { option in
                    Text(filterLabel(option)).tag(option.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 118)

            Picker("", selection: $categoryFilter) {
                Text(L10n.text("categoryFilterAll", language)).tag(Self.allCategoriesFilterValue)
                if categoryOptions.contains(where: { !$0.isEmpty }) {
                    Divider()
                    ForEach(categoryOptions, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                Divider()
                Text(L10n.text("categoryFilterUncategorized", language)).tag(Self.uncategorizedFilterValue)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 150)

            Button {
                isAlwaysOnTop.toggle()
                updateWindowPresentation()
            } label: {
                Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(PinFilterButtonStyle(colorScheme: colorScheme, isSelected: isAlwaysOnTop))
            .help(L10n.text("pinOnTop", language))

            Button {
                enterImmersiveMode()
            } label: {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(PinFilterButtonStyle(colorScheme: colorScheme, isSelected: false))
            .help(L10n.text("immersiveMode", language))
        }
        .frame(maxWidth: 398)
        .onChange(of: categoryOptions) { options in
            if categoryFilter != Self.allCategoriesFilterValue,
               categoryFilter != Self.uncategorizedFilterValue,
               !options.contains(categoryFilter) {
                categoryFilter = Self.allCategoriesFilterValue
            }
        }
    }

    private func enterImmersiveMode() {
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 22)) {
            isImmersiveMode = true
        }
    }

    private func exitImmersiveMode() {
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 22)) {
            isImmersiveMode = false
        }
    }

    private func updateWindowPresentation(animated: Bool = true) {
        DispatchQueue.main.async {
            for window in NSApp.windows {
                guard window.sheetParent == nil else { continue }
                window.level = isAlwaysOnTop ? .floating : .normal
                window.isOpaque = !isImmersiveMode
                window.backgroundColor = isImmersiveMode ? .clear : .windowBackgroundColor
                window.hasShadow = !isImmersiveMode

                window.standardWindowButton(.closeButton)?.isHidden = isImmersiveMode
                window.standardWindowButton(.miniaturizeButton)?.isHidden = isImmersiveMode
                window.standardWindowButton(.zoomButton)?.isHidden = isImmersiveMode

                let targetSize = isImmersiveMode
                    ? NSSize(width: 260, height: min(max(150, displayItemsHeightEstimate), 420))
                    : NSSize(width: max(window.frame.width, 760), height: max(window.frame.height, 650))
                resize(window: window, to: targetSize, animated: animated)
            }
        }
    }

    private var displayItemsHeightEstimate: CGFloat {
        let rows = ceil(Double(max(displayItems.count, 1)) / 3.0)
        return CGFloat(rows) * 68 + 80
    }

    private func resize(window: NSWindow, to size: NSSize, animated: Bool) {
        var frame = window.frame
        let oldMidX = frame.midX
        let oldMidY = frame.midY
        frame.size = size
        frame.origin.x = oldMidX - size.width / 2
        frame.origin.y = oldMidY - size.height / 2

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.42
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(frame, display: true)
            }
        } else {
            window.setFrame(frame, display: true)
        }
    }

    private func toggleSortMode() {
        let current = SortMode(rawValue: sortModeRaw) ?? .remainingDays
        sortModeRaw = (current == .remainingDays) ? SortMode.manual.rawValue : SortMode.remainingDays.rawValue
    }

    private func toggleSortDirection() {
        guard sortMode == .remainingDays else { return }
        store.sortByRemainingDays(on: now, ascending: sortAscending)
        sortAscending.toggle()
    }

    private func checkAndSendDuePushes() {
        guard pushEnabled else { return }
        guard !isCheckingPushes else { return }
        let address = barkPushAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty, address != "https://api.day.app/" else { return }

        isCheckingPushes = true

        let snapshot = store.items.filter { !$0.isArchived }
        Task {
            var sentKeys = Set(UserDefaults.standard.stringArray(forKey: Self.sentReminderDefaultsKey) ?? [])
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            for item in snapshot {
                let expiry = calendar.startOfDay(for: item.expiryDate)
                let days = calendar.dateComponents([.day], from: today, to: expiry).day ?? 0
                guard days >= 0 else { continue }

                let offsets = Set(item.reminderOffsets)
                guard offsets.contains(days) else { continue }

                let key = reminderKey(item: item, triggerDays: days, calendar: calendar)
                guard !sentKeys.contains(key) else { continue }

                do {
                    try await BarkPushService.send(
                        pushAddress: address,
                        itemName: item.name,
                        daysUntilExpiry: days,
                        language: language
                    )
                    sentKeys.insert(key)
                    UserDefaults.standard.set(Array(sentKeys).sorted(), forKey: Self.sentReminderDefaultsKey)
                } catch {
                    // Network failures should not interrupt normal app use.
                }
            }

            await MainActor.run {
                isCheckingPushes = false
            }
        }
    }

    private func reminderKey(item: CountdownItem, triggerDays: Int, calendar: Calendar) -> String {
        let expiry = calendar.startOfDay(for: item.expiryDate)
        let components = calendar.dateComponents([.year, .month, .day], from: expiry)
        let dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return "\(item.id.uuidString)|\(triggerDays)|\(dateKey)"
    }

    private static let sentReminderDefaultsKey = "barkSentReminderKeys"

    private func recoveryAlert(for notice: DataRecoveryNotice) -> Alert {
        let title = Text(recoveryTitle(for: notice))
        let message = Text(recoveryMessage(for: notice))

        guard recoveryBackupURL(for: notice) != nil else {
            return Alert(
                title: title,
                message: message,
                dismissButton: .default(Text(L10n.text("ok", language)))
            )
        }

        return Alert(
            title: title,
            message: message,
            primaryButton: .default(Text(L10n.text("showBackup", language))) {
                revealRecoveryBackup(for: notice)
            },
            secondaryButton: .default(Text(L10n.text("ok", language)))
        )
    }

    private func recoveryTitle(for notice: DataRecoveryNotice) -> String {
        switch notice.kind {
        case .restored:
            return L10n.text("dataRecoveredTitle", language)
        case .manualRecoveryNeeded:
            return L10n.text("dataRecoveryNeededTitle", language)
        }
    }

    private func recoveryMessage(for notice: DataRecoveryNotice) -> String {
        switch notice.kind {
        case .restored(let restoredFromURL):
            if restoredFromURL != nil, notice.corruptedBackupURL != nil {
                return L10n.text("dataRecoveredMessage", language)
            }
            return L10n.text("dataRecoveredWithoutBackupPathMessage", language)
        case .manualRecoveryNeeded:
            return L10n.text("dataRecoveryNeededMessage", language)
        }
    }

    private func recoveryBackupURL(for notice: DataRecoveryNotice) -> URL? {
        notice.corruptedBackupURL
    }

    private func revealRecoveryBackup(for notice: DataRecoveryNotice) {
        guard let url = recoveryBackupURL(for: notice) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func filterLabel(_ option: DashboardFilter) -> String {
        switch option {
        case .active: return L10n.text("filterActive", language)
        case .all: return L10n.text("filterAll", language)
        case .within30: return L10n.text("filterWithin30", language)
        case .overdue: return L10n.text("filterOverdue", language)
        case .archived: return L10n.text("filterArchived", language)
        }
    }

    private static let allCategoriesFilterValue = "__all_categories__"
    private static let uncategorizedFilterValue = "__uncategorized__"
}

private struct PinFilterButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? Color.white : RadixPalette.mutedText(colorScheme))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fill(configuration: configuration))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.14), value: isSelected)
    }

    private func fill(configuration: Configuration) -> Color {
        if isSelected {
            return RadixPalette.accentSolid(colorScheme)
        }
        if configuration.isPressed {
            return RadixPalette.hoverBackground(colorScheme)
        }
        return RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.62 : 0.76)
    }
}

private struct ImmersiveDashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

    let items: [CountdownItem]
    let now: Date
    let onExit: () -> Void

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(items) { item in
                    ImmersiveRingItem(item: item, now: now)
                        .transition(.scale(scale: 0.72).combined(with: .opacity))
                }
            }
            .padding(20)
            .animation(.interpolatingSpring(stiffness: 190, damping: 24), value: items.map(\.id))

            Button(action: onExit) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(ImmersiveExitButtonStyle(colorScheme: colorScheme))
            .help(L10n.text("exitImmersive", language))
            .padding(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(54), spacing: 14), count: min(max(items.count, 1), 3))
    }
}

private struct ImmersiveRingItem: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    let item: CountdownItem
    let now: Date

    private var remainingDays: Int {
        item.remainingDays(on: now)
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

    private var urgency: UrgencyBand {
        UrgencyBand(days: remainingDays)
    }

    var body: some View {
        RingView(
            progress: progress,
            color: urgency.color(colorScheme),
            lineWidth: 7,
            trackColor: RadixPalette.border(colorScheme).opacity(0.62)
        ) {
            EmptyView()
        }
        .frame(width: 46, height: 46)
        .padding(4)
        .scaleEffect(isHovering ? 1.10 : 1)
        .contentShape(Circle())
        .help(item.name)
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.interpolatingSpring(stiffness: 210, damping: 20), value: isHovering)
    }
}

private struct ImmersiveExitButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(RadixPalette.mutedText(colorScheme))
            .background(
                Circle()
                    .fill(RadixPalette.elementBackground(colorScheme).opacity(0.54))
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

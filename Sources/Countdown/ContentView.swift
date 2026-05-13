import AppKit
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
    @AppStorage("pushSevenDaysEnabled") private var pushSevenDaysEnabled: Bool = true
    @AppStorage("pushDueDayEnabled") private var pushDueDayEnabled: Bool = true
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

    @State private var now = Date()
    @State private var isAdding = false
    @State private var isShowingSettings = false
    @State private var isCheckingPushes = false
    @State private var editingItem: CountdownItem?
    @State private var draggingItemID: UUID?
    @State private var searchText = ""
    @State private var filterRaw = DashboardFilter.active.rawValue

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

    private var displayItems: [CountdownItem] {
        store.items.filter { item in
            guard item.matchesSearch(searchText) else { return false }
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
        .frame(minWidth: 375, idealWidth: 760, minHeight: 500, idealHeight: 650)
        .onAppear {
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
        .onChange(of: pushSevenDaysEnabled) { _ in
            checkAndSendDuePushes()
        }
        .onChange(of: pushDueDayEnabled) { _ in
            checkAndSendDuePushes()
        }
        .sheet(isPresented: $isAdding) {
            ItemEditorView(mode: .add, initialItem: nil) { result in
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
            ItemEditorView(mode: .edit, initialItem: item) { result in
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

    private var dashboardFilterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RadixPalette.faintText(colorScheme))

                TextField(text("searchPlaceholder"), text: $searchText)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.62 : 0.76))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(RadixPalette.border(colorScheme).opacity(0.38), lineWidth: 1)
            )

            Picker("", selection: $filterRaw) {
                ForEach(DashboardFilter.allCases) { option in
                    Text(filterLabel(option)).tag(option.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 118)
        }
        .frame(maxWidth: 560)
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
        let legacySevenDaysEnabled = pushSevenDaysEnabled
        let legacyDueDayEnabled = pushDueDayEnabled

        Task {
            var sentKeys = Set(UserDefaults.standard.stringArray(forKey: Self.sentReminderDefaultsKey) ?? [])
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            for item in snapshot {
                let expiry = calendar.startOfDay(for: item.expiryDate)
                let days = calendar.dateComponents([.day], from: today, to: expiry).day ?? 0
                guard days >= 0 else { continue }

                let offsets = effectiveReminderOffsets(
                    for: item,
                    legacySevenDaysEnabled: legacySevenDaysEnabled,
                    legacyDueDayEnabled: legacyDueDayEnabled
                )
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

    private func effectiveReminderOffsets(
        for item: CountdownItem,
        legacySevenDaysEnabled: Bool,
        legacyDueDayEnabled: Bool
    ) -> Set<Int> {
        var offsets = Set(item.reminderOffsets)

        if !legacySevenDaysEnabled {
            offsets.remove(7)
        }
        if !legacyDueDayEnabled {
            offsets.remove(0)
        }

        return offsets
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
        case .active: return text("active")
        case .all: return text("all")
        case .within30: return text("within30")
        case .overdue: return text("overdue")
        case .archived: return text("archived")
        }
    }

    private func text(_ key: String) -> String {
        let zh: [String: String] = [
            "searchPlaceholder": "搜索名称、备注、分类或链接",
            "active": "进行中",
            "all": "全部",
            "within30": "30天内",
            "overdue": "已过期",
            "archived": "归档",
        ]
        let en: [String: String] = [
            "searchPlaceholder": "Search name, note, category, or link",
            "active": "Active",
            "all": "All",
            "within30": "30 days",
            "overdue": "Overdue",
            "archived": "Archived",
        ]
        return language == .simplifiedChinese ? (zh[key] ?? en[key] ?? key) : (en[key] ?? key)
    }
}

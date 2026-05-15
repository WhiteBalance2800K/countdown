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
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

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
        }
        .frame(maxWidth: 310)
        .onChange(of: categoryOptions) { options in
            if categoryFilter != Self.allCategoriesFilterValue,
               categoryFilter != Self.uncategorizedFilterValue,
               !options.contains(categoryFilter) {
                categoryFilter = Self.allCategoriesFilterValue
            }
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

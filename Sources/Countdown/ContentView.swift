import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ItemsStore
    @EnvironmentObject private var commandCenter: AppCommandCenter
    @Environment(\.scenePhase) private var scenePhase
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

    private enum SortMode: String {
        case remainingDays
        case manual
    }

    private var sortMode: SortMode { SortMode(rawValue: sortModeRaw) ?? .remainingDays }

    private var displayItems: [CountdownItem] {
        store.items
    }

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SoftBackground()

            SoftDashboardView(
                items: displayItems,
                now: now,
                isManualOrder: sortMode == .manual,
                store: store,
                draggingItemID: $draggingItemID,
                onEdit: { editingItem = $0 },
                onDelete: { store.remove($0) }
            )

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
            // Cheap refresh to ensure day boundary updates.
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
                case .save(let name, let expiryDate):
                    store.add(name: name, expiryDate: expiryDate)
                }

                isAdding = false
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditorView(mode: .edit, initialItem: item) { result in
                switch result {
                case .cancel:
                    break
                case .save(let name, let expiryDate):
                    var updated = item
                    updated.name = name
                    updated.expiryDate = expiryDate
                    updated.updatedAt = Date()
                    store.update(updated)
                }

                editingItem = nil
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            PushSettingsView()
        }
        .alert(item: $store.recoveryNotice) { notice in
            recoveryAlert(for: notice)
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
        guard pushSevenDaysEnabled || pushDueDayEnabled else { return }

        isCheckingPushes = true

        let snapshot = store.items
        let sevenDaysEnabled = pushSevenDaysEnabled
        let dueDayEnabled = pushDueDayEnabled

        Task {
            var sentKeys = Set(UserDefaults.standard.stringArray(forKey: Self.sentReminderDefaultsKey) ?? [])
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            for item in snapshot {
                let expiry = calendar.startOfDay(for: item.expiryDate)
                let days = calendar.dateComponents([.day], from: today, to: expiry).day ?? 0
                let shouldSend = (days == 7 && sevenDaysEnabled) || (days == 0 && dueDayEnabled)
                guard shouldSend else { continue }

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
}

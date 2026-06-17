import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct PushSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ItemsStore

    @AppStorage("pushEnabled") private var pushEnabled: Bool = false
    @AppStorage("barkPushAddress") private var barkPushAddress: String = "https://api.day.app/"
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw: String = AppAppearanceMode.system.rawValue
    @AppStorage("launchAtLoginEnabled") private var launchAtLoginEnabled: Bool = false

    @State private var testState: TestState = .idle
    @State private var launchAtLoginError = false
    @State private var dataTransferMessage: String?
    @State private var dataTransferIsError = false

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    var body: some View {
        ZStack {
            RadixPalette.appBackground(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 14) {
                        languageAppearanceSection
                        launchAtLoginSection
                        toggleRow
                        addressField
                        reminderInfoSection
                        dataSection
                        projectSection
                    }
                    .padding(18)
                }

                footer
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(RadixPalette.subtleBackground(colorScheme))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.38 : 0.12), radius: 28, x: 0, y: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(RadixPalette.border(colorScheme).opacity(0.48), lineWidth: 1)
            )
            .padding(18)
        }
        .frame(width: 430, height: 610)
        .onAppear {
            syncLaunchAtLoginStatus()
        }
    }

    private var header: some View {
        ZStack {
            Text(L10n.text("settings", language))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RadixPalette.text(colorScheme))

            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(SettingsIconButtonStyle(colorScheme: colorScheme))
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.38 : 0.42))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RadixPalette.border(colorScheme).opacity(0.38))
                .frame(height: 1)
        }
    }

    private var toggleRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text("enableBark", language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                Text(L10n.text("runtimeCheck", language))
                    .font(.system(size: 11))
                    .foregroundStyle(RadixPalette.faintText(colorScheme))
            }

            Spacer()

            Toggle("", isOn: $pushEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(12)
        .background(settingsSurface)
    }

    private var launchAtLoginSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text("launchAtLogin", language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                Text(L10n.text(launchAtLoginError ? "launchAtLoginFailed" : "launchAtLoginSubtitle", language))
                    .font(.system(size: 11))
                    .foregroundStyle(launchAtLoginError ? RadixPalette.dangerSolid(colorScheme) : RadixPalette.faintText(colorScheme))
            }

            Spacer()

            Toggle("", isOn: launchAtLoginBinding)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(12)
        .background(settingsSurface)
    }

    private var languageAppearanceSection: some View {
        HStack(spacing: 12) {
            Text("Language")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(RadixPalette.text(colorScheme))

            Picker("", selection: $appLanguageRaw) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.nativeName).tag(option.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: 118)

            Spacer(minLength: 0)

            Picker("", selection: $appAppearanceModeRaw) {
                ForEach(AppAppearanceMode.allCases) { option in
                    Image(systemName: appearanceIcon(option))
                        .accessibilityLabel(appearanceLabel(option))
                        .tag(option.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: 96)
            .help(L10n.text("appearance", language))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(settingsSurface)
    }

    private var addressField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("barkAddress", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 9) {
                Image(systemName: "link")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RadixPalette.accentSolid(colorScheme))

                TextField(L10n.text("barkAddressPlaceholder", language), text: $barkPushAddress)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(fieldBackground)
            .overlay(fieldBorder)

            Text(L10n.text("barkAddressHelp", language))
                .font(.system(size: 10))
                .foregroundStyle(RadixPalette.faintText(colorScheme))
                .lineLimit(2)

            testPushRow
        }
    }

    private var testPushRow: some View {
        HStack(spacing: 10) {
            Button {
                sendTestPush()
            } label: {
                Label(L10n.text("testPush", language), systemImage: "paperplane.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(SettingsPrimaryButtonStyle(colorScheme: colorScheme))
            .disabled(!canSendTest)

            Text(testState.message(language))
                .font(.system(size: 11))
                .foregroundStyle(testState.color(colorScheme))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    private var reminderInfoSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RadixPalette.accentSolid(colorScheme))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text("reminderSettingsTitle", language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                Text(L10n.text("reminderSettingsHelp", language))
                    .font(.system(size: 11))
                    .foregroundStyle(RadixPalette.faintText(colorScheme))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(settingsSurface)
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(V06Text.text("data", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 10) {
                Button {
                    reveal(store.appSupportDirectoryURL())
                } label: {
                    Label(V06Text.text("openDataFolder", language), systemImage: "folder")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))

                Button {
                    reveal(store.backupsDirectoryURL())
                } label: {
                    Label(V06Text.text("openBackupFolder", language), systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))
            }

            HStack(spacing: 10) {
                Button {
                    importData(format: .json)
                } label: {
                    Label(L10n.text("importJSON", language), systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))

                Button {
                    importData(format: .csv)
                } label: {
                    Label(L10n.text("importCSV", language), systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))
            }

            HStack(spacing: 10) {
                Button {
                    exportData(format: .json)
                } label: {
                    Label(L10n.text("exportJSON", language), systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))

                Button {
                    exportData(format: .csv)
                } label: {
                    Label(L10n.text("exportCSV", language), systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))
            }

            if let dataTransferMessage {
                Text(dataTransferMessage)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(dataTransferIsError ? RadixPalette.dangerSolid(colorScheme) : RadixPalette.successSolid(colorScheme))
                    .lineLimit(2)
            }
        }
    }

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(L10n.text("projectLinks", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 10) {
                Button {
                    openWeb("https://github.com/WhiteBalance2800K/countdown")
                } label: {
                    Label(L10n.text("openGitHub", language), systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))

                Button {
                    openWeb("https://github.com/WhiteBalance2800K/countdown/issues/new")
                } label: {
                    Label(L10n.text("feedbackIssue", language), systemImage: "exclamationmark.bubble")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(L10n.text("dedupeHint", language))
                .font(.system(size: 10))
                .foregroundStyle(RadixPalette.faintText(colorScheme))
                .lineLimit(2)

            Spacer()

            Button(L10n.text("done", language)) {
                dismiss()
            }
            .buttonStyle(SettingsSecondaryButtonStyle(colorScheme: colorScheme))
            .keyboardShortcut(.defaultAction)
        }
        .padding(18)
        .background(RadixPalette.subtleBackground(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RadixPalette.border(colorScheme).opacity(0.32))
                .frame(height: 1)
        }
    }

    private var canSendTest: Bool {
        !barkPushAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginEnabled },
            set: { setLaunchAtLogin($0) }
        )
    }

    private var settingsSurface: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.56 : 0.68))
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(RadixPalette.appBackground(colorScheme))
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(RadixPalette.border(colorScheme).opacity(0.46), lineWidth: 1)
    }

    private func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openWeb(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func importData(format: CountdownDataFileFormat) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [contentType(for: format)]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let count = try store.importData(from: url, format: format)
            dataTransferIsError = false
            dataTransferMessage = String(format: L10n.text("dataImportSuccess", language), count)
        } catch {
            dataTransferIsError = true
            dataTransferMessage = L10n.text("dataTransferFailed", language)
        }
    }

    private func exportData(format: CountdownDataFileFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [contentType(for: format)]
        panel.nameFieldStringValue = "Countdown-\(Self.filenameDate()).\(format.fileExtension)"

        guard panel.runModal() == .OK, var url = panel.url else { return }
        if url.pathExtension.isEmpty {
            url.appendPathExtension(format.fileExtension)
        }

        do {
            let data = try store.exportData(format: format)
            try data.write(to: url, options: [.atomic])
            dataTransferIsError = false
            dataTransferMessage = String(format: L10n.text("dataExportSuccess", language), format.fileExtension.uppercased())
        } catch {
            dataTransferIsError = true
            dataTransferMessage = L10n.text("dataTransferFailed", language)
        }
    }

    private func contentType(for format: CountdownDataFileFormat) -> UTType {
        switch format {
        case .json:
            return .json
        case .csv:
            return .commaSeparatedText
        }
    }

    private static func filenameDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    private func appearanceLabel(_ mode: AppAppearanceMode) -> String {
        switch mode {
        case .system:
            return L10n.text("appearanceSystem", language)
        case .light:
            return L10n.text("appearanceLight", language)
        case .dark:
            return L10n.text("appearanceDark", language)
        }
    }

    private func appearanceIcon(_ mode: AppAppearanceMode) -> String {
        switch mode {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    private func sendTestPush() {
        testState = .sending
        let address = barkPushAddress
        let currentLanguage = language

        Task {
            do {
                try await BarkPushService.send(
                    pushAddress: address,
                    itemName: L10n.text("testItem", currentLanguage),
                    daysUntilExpiry: 7,
                    language: currentLanguage
                )
                await MainActor.run {
                    testState = .success
                }
            } catch {
                await MainActor.run {
                    testState = .failed
                }
            }
        }
    }

    private func syncLaunchAtLoginStatus() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        launchAtLoginError = false
    }

    private func setLaunchAtLogin(_ isEnabled: Bool) {
        launchAtLoginError = false

        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = true
        }

        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }
}

private enum TestState {
    case idle
    case sending
    case success
    case failed

    func message(_ language: AppLanguage) -> String {
        switch self {
        case .idle: return L10n.text("testIdle", language)
        case .sending: return L10n.text("testSending", language)
        case .success: return L10n.text("testSuccess", language)
        case .failed: return L10n.text("testFailed", language)
        }
    }

    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .idle, .sending:
            return RadixPalette.faintText(scheme)
        case .success:
            return RadixPalette.successSolid(scheme)
        case .failed:
            return RadixPalette.dangerSolid(scheme)
        }
    }
}

private struct SettingsIconButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(RadixPalette.mutedText(colorScheme))
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(configuration.isPressed ? RadixPalette.hoverBackground(colorScheme) : RadixPalette.elementBackground(colorScheme).opacity(0.72))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SettingsPrimaryButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Color.white : RadixPalette.faintText(colorScheme))
            .padding(.horizontal, 13)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isEnabled ? RadixPalette.accentSolid(colorScheme) : RadixPalette.elementBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isEnabled ? Color.clear : RadixPalette.border(colorScheme).opacity(0.42), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SettingsSecondaryButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(RadixPalette.mutedText(colorScheme))
            .padding(.horizontal, 15)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed ? RadixPalette.hoverBackground(colorScheme) : RadixPalette.elementBackground(colorScheme).opacity(0.8))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

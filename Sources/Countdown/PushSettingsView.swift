import SwiftUI

struct PushSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("pushEnabled") private var pushEnabled: Bool = false
    @AppStorage("barkPushAddress") private var barkPushAddress: String = "https://api.day.app/"
    @AppStorage("pushSevenDaysEnabled") private var pushSevenDaysEnabled: Bool = true
    @AppStorage("pushDueDayEnabled") private var pushDueDayEnabled: Bool = true

    @State private var testState: TestState = .idle

    var body: some View {
        ZStack {
            RadixPalette.appBackground(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(spacing: 14) {
                    toggleRow
                    addressField
                    timingSection
                    testSection
                }
                .padding(18)

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
        .frame(width: 430)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RadixPalette.accentElement(colorScheme))
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RadixPalette.accentSolid(colorScheme))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text("设置")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                Text("Bark 到期推送")
                    .font(.system(size: 12))
                    .foregroundStyle(RadixPalette.mutedText(colorScheme))
            }

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
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
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
                Text("启用 Bark 推送")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                Text("应用运行时检查到期项目")
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

    private var addressField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bark 推送地址")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 9) {
                Image(systemName: "link")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RadixPalette.accentSolid(colorScheme))

                TextField("https://api.day.app/你的Key", text: $barkPushAddress)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(fieldBackground)
            .overlay(fieldBorder)

            Text("填写 Bark App 里复制的基础地址，格式如 https://api.day.app/你的Key")
                .font(.system(size: 10))
                .foregroundStyle(RadixPalette.faintText(colorScheme))
                .lineLimit(2)
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("推送时间")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            VStack(spacing: 8) {
                SettingsCheckboxRow(
                    title: "到期前 7 天",
                    subtitle: "剩余 7 天时推送项目名称",
                    isOn: $pushSevenDaysEnabled
                )

                SettingsCheckboxRow(
                    title: "到期当天",
                    subtitle: "剩余 0 天时推送项目名称",
                    isOn: $pushDueDayEnabled
                )
            }
        }
    }

    private var testSection: some View {
        HStack(spacing: 10) {
            Button {
                sendTestPush()
            } label: {
                Label("测试推送", systemImage: "paperplane.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(SettingsPrimaryButtonStyle(colorScheme: colorScheme))
            .disabled(!canSendTest)

            Text(testState.message)
                .font(.system(size: 11))
                .foregroundStyle(testState.color(colorScheme))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        HStack {
            Text("推送记录会去重，同一项目同一到期日不会重复发送。")
                .font(.system(size: 10))
                .foregroundStyle(RadixPalette.faintText(colorScheme))
                .lineLimit(2)

            Spacer()

            Button("完成") {
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

    private func sendTestPush() {
        testState = .sending
        let address = barkPushAddress

        Task {
            do {
                try await BarkPushService.send(pushAddress: address, itemName: "测试项目", daysUntilExpiry: 7)
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
}

private struct SettingsCheckboxRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(RadixPalette.faintText(colorScheme))
            }
        }
        .toggleStyle(.checkbox)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.56 : 0.68))
        )
    }
}

private enum TestState {
    case idle
    case sending
    case success
    case failed

    var message: String {
        switch self {
        case .idle: return "发送一条测试消息"
        case .sending: return "发送中..."
        case .success: return "已发送"
        case .failed: return "发送失败，请检查地址"
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

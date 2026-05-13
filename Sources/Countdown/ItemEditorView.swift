import SwiftUI

struct ItemEditorView: View {
    enum EditorMode {
        case add
        case edit
    }

    enum EditorResult {
        case cancel
        case save(name: String, expiryDate: Date, note: String, reminderOffsets: [Int])
    }

    enum ExpiryInputMode: String, CaseIterable, Identifiable {
        case remainingDays
        case date

        var id: String { rawValue }

        var label: String {
            switch self {
            case .date: return "日期"
            case .remainingDays: return "天数"
            }
        }

        var iconName: String {
            switch self {
            case .date: return "calendar"
            case .remainingDays: return "timer"
            }
        }
    }

    let mode: EditorMode
    let initialItem: CountdownItem?
    let onDone: (EditorResult) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.simplifiedChinese.rawValue

    @State private var name: String
    @State private var inputMode: ExpiryInputMode = .remainingDays
    @State private var expiryDate: Date
    @State private var remainingDays: Int = 30
    @State private var note: String
    @State private var reminderOffsetsText: String
    @State private var didAppear = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedReminderOffsets: [Int] {
        let values = reminderOffsetsText
            .split { $0 == "," || $0 == "，" || $0 == " " || $0 == "\n" || $0 == "\t" }
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        return CountdownItem.normalizedReminderOffsets(values)
    }

    private var language: AppLanguage {
        AppLanguage.current(from: appLanguageRaw)
    }

    private var finalExpiryDate: Date {
        let cal = Calendar.current
        if inputMode == .date {
            return cal.startOfDay(for: expiryDate)
        }
        return cal.startOfDay(for: computedExpiryFromRemainingDays())
    }

    private var previewDays: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: finalExpiryDate
        ).day ?? 0
    }

    init(mode: EditorMode, initialItem: CountdownItem?, onDone: @escaping (EditorResult) -> Void) {
        self.mode = mode
        self.initialItem = initialItem
        self.onDone = onDone

        _name = State(initialValue: initialItem?.name ?? "")
        _expiryDate = State(initialValue: initialItem?.expiryDate ?? Date())
        _note = State(initialValue: initialItem?.note ?? "")
        _reminderOffsetsText = State(initialValue: (initialItem?.reminderOffsets ?? CountdownItem.defaultReminderOffsets).map(String.init).joined(separator: ", "))
    }

    var body: some View {
        ZStack {
            RadixPalette.appBackground(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        titleField
                        modeSelector

                        if inputMode == .remainingDays {
                            remainingDaysEditor
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            dateEditor
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        previewStrip
                        noteField
                        reminderOffsetsField
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                }

                footer
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(RadixPalette.subtleBackground(colorScheme))
                    .shadow(color: shadowColor, radius: 28, x: 0, y: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(RadixPalette.border(colorScheme).opacity(colorScheme == .dark ? 0.54 : 0.46), lineWidth: 1)
            )
            .padding(18)
            .scaleEffect(didAppear ? 1 : 0.985)
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 8)
            .animation(.easeOut(duration: 0.18), value: didAppear)
        }
        .frame(width: 430, height: 580)
        .onAppear {
            configureInitialValues()
            didAppear = true
        }
        .onChange(of: inputMode) { newValue in
            let cal = Calendar.current
            switch newValue {
            case .date:
                expiryDate = cal.startOfDay(for: computedExpiryFromRemainingDays())
            case .remainingDays:
                let today = cal.startOfDay(for: Date())
                let target = cal.startOfDay(for: expiryDate)
                remainingDays = clampDays(max(cal.dateComponents([.day], from: today, to: target).day ?? 0, 0))
            }
        }
        .onChange(of: remainingDays) { newValue in
            let clamped = clampDays(newValue)
            if newValue != clamped {
                remainingDays = clamped
            }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(L10n.text("itemName", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 9) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RadixPalette.accentSolid(colorScheme))

                TextField(L10n.text("itemPlaceholder", language), text: $name)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                    .textFieldStyle(.plain)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(fieldBackground)
            .overlay(fieldBorder)
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 6) {
            ForEach(ExpiryInputMode.allCases) { option in
                Button {
                    withAnimation(.easeOut(duration: 0.16)) {
                        inputMode = option
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.iconName)
                            .font(.system(size: 12, weight: .semibold))
                        Text(inputModeLabel(option))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                }
                .buttonStyle(SegmentedDialogButtonStyle(
                    colorScheme: colorScheme,
                    isSelected: inputMode == option
                ))
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.54 : 0.72))
        )
    }

    private var remainingDaysEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("remainingDays", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 10) {
                dayAdjustButton(systemName: "minus", action: { remainingDays = clampDays(remainingDays - 1) })

                TextField(L10n.text("daysMode", language), value: $remainingDays, format: .number)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .onSubmit {
                        remainingDays = clampDays(remainingDays)
                    }

                dayAdjustButton(systemName: "plus", action: { remainingDays = clampDays(remainingDays + 1) })
            }
            .padding(10)
            .frame(height: 76)
            .background(fieldBackground)
            .overlay(fieldBorder)
        }
    }

    private var dateEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("expiryDate", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RadixPalette.accentSolid(colorScheme))

                DatePicker("", selection: $expiryDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(fieldBackground)
            .overlay(fieldBorder)
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("note", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            TextEditor(text: $note)
                .font(.system(size: 13))
                .foregroundStyle(RadixPalette.text(colorScheme))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 86)
                .background(fieldBackground)
                .overlay(fieldBorder)
        }
    }

    private var reminderOffsetsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("customReminderOffsets", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            HStack(spacing: 9) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RadixPalette.accentSolid(colorScheme))

                TextField("30, 7, 1, 0", text: $reminderOffsetsText)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(fieldBackground)
            .overlay(fieldBorder)

            Text(String(format: L10n.text("customReminderOffsetsHelp", language), parsedReminderOffsets.map(String.init).joined(separator: ", ")))
                .font(.system(size: 10))
                .foregroundStyle(RadixPalette.faintText(colorScheme))
                .lineLimit(2)
        }
    }

    private var previewStrip: some View {
        HStack(spacing: 10) {
            previewPill(
                iconName: "calendar",
                title: L10n.text("due", language),
                value: DateFormatters.shortDateString(from: finalExpiryDate, language: language)
            )

            previewPill(
                iconName: "clock",
                title: L10n.text("remaining", language),
                value: previewDays <= 0 ? L10n.text("today", language) : L10n.daysValue(previewDays, language)
            )
        }
    }

    private func previewPill(iconName: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RadixPalette.accentSolid(colorScheme))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(RadixPalette.faintText(colorScheme))
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RadixPalette.text(colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RadixPalette.elementBackground(colorScheme).opacity(colorScheme == .dark ? 0.56 : 0.68))
        )
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(L10n.text("cancel", language)) {
                cancel()
            }
            .buttonStyle(SecondaryDialogButtonStyle(colorScheme: colorScheme))

            Spacer()

            Button(mode == .add ? L10n.text("add", language) : L10n.text("save", language)) {
                save()
            }
            .buttonStyle(PrimaryDialogButtonStyle(colorScheme: colorScheme))
            .keyboardShortcut(.defaultAction)
            .disabled(trimmedName.isEmpty)
        }
        .padding(18)
        .background(RadixPalette.subtleBackground(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RadixPalette.border(colorScheme).opacity(0.32))
                .frame(height: 1)
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(RadixPalette.appBackground(colorScheme))
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(RadixPalette.border(colorScheme).opacity(0.46), lineWidth: 1)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.38)
            : Color.black.opacity(0.12)
    }

    private func dayAdjustButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(QuietIconButtonStyle(colorScheme: colorScheme))
    }

    private func inputModeLabel(_ mode: ExpiryInputMode) -> String {
        switch mode {
        case .remainingDays:
            return L10n.text("daysMode", language)
        case .date:
            return L10n.text("dateMode", language)
        }
    }

    private func cancel() {
        onDone(.cancel)
        dismiss()
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        onDone(.save(
            name: trimmedName,
            expiryDate: finalExpiryDate,
            note: trimmedNote,
            reminderOffsets: parsedReminderOffsets
        ))
        dismiss()
    }

    private func configureInitialValues() {
        guard let initialItem else {
            expiryDate = Date()
            remainingDays = 30
            inputMode = .remainingDays
            note = ""
            reminderOffsetsText = CountdownItem.defaultReminderOffsets.map(String.init).joined(separator: ", ")
            return
        }

        let cal = Calendar.current
        let d = initialItem.remainingDays(on: Date(), calendar: cal)
        expiryDate = initialItem.expiryDate
        note = initialItem.note
        reminderOffsetsText = initialItem.reminderOffsets.map(String.init).joined(separator: ", ")

        if d < 0 {
            remainingDays = 0
            inputMode = .date
        } else {
            remainingDays = d
            inputMode = .remainingDays
        }
    }

    private func computedExpiryFromRemainingDays() -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: remainingDays, to: today) ?? today
    }

    private func clampDays(_ value: Int) -> Int {
        min(max(value, 0), 3650)
    }
}

private struct QuietIconButtonStyle: ButtonStyle {
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

private struct SegmentedDialogButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? RadixPalette.text(colorScheme) : RadixPalette.mutedText(colorScheme))
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(selectedFill(configuration: configuration))
                    .shadow(color: isSelected ? Color.black.opacity(colorScheme == .dark ? 0.24 : 0.09) : .clear, radius: 8, x: 0, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.16), value: isSelected)
    }

    private func selectedFill(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return RadixPalette.hoverBackground(colorScheme)
        }
        if isSelected {
            return RadixPalette.subtleBackground(colorScheme)
        }
        return .clear
    }
}

private struct PrimaryDialogButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isEnabled ? Color.white : RadixPalette.faintText(colorScheme))
            .padding(.horizontal, 18)
            .frame(height: 36)
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

private struct SecondaryDialogButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(RadixPalette.mutedText(colorScheme))
            .padding(.horizontal, 15)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed ? RadixPalette.hoverBackground(colorScheme) : RadixPalette.elementBackground(colorScheme).opacity(0.8))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

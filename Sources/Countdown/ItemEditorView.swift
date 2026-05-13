import SwiftUI

struct ItemEditorView: View {
    // ... 现有属性保持不变 ...

    @State private var category: String
    @State private var link: String
    @State private var isArchived: Bool
    @State private var repeatRule: RepeatRule
    @State private var repeatCustomDays: Int

    init(mode: EditorMode, initialItem: CountdownItem?, onDone: @escaping (EditorResult) -> Void) {
        self.mode = mode
        self.initialItem = initialItem
        self.onDone = onDone

        _name = State(initialValue: initialItem?.name ?? "")
        _expiryDate = State(initialValue: initialItem?.expiryDate ?? Date())
        _note = State(initialValue: initialItem?.note ?? "")
        _reminderOffsetsText = State(initialValue: (initialItem?.reminderOffsets ?? CountdownItem.defaultReminderOffsets).map(String.init).joined(separator: ", "))

        _category = State(initialValue: initialItem?.category ?? "")
        _link = State(initialValue: initialItem?.link ?? "")
        _isArchived = State(initialValue: initialItem?.isArchived ?? false)
        _repeatRule = State(initialValue: initialItem?.repeatRule ?? .none)
        _repeatCustomDays = State(initialValue: initialItem?.repeatCustomDays ?? 30)
    }

    var body: some View {
        ZStack {
            RadixPalette.appBackground(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        titleField
                        modeSelector
                        if inputMode == .remainingDays { remainingDaysEditor.transition(.opacity) } else { dateEditor.transition(.opacity) }
                        previewStrip
                        noteField
                        reminderOffsetsField

                        // --- v0.8 新增字段 ---
                        categoryField
                        linkField
                        repeatRuleField
                        archiveToggle
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                }
                footer
            }
            .background(RadixPalette.subtleBackground(colorScheme).cornerRadius(18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(RadixPalette.border(colorScheme).opacity(colorScheme == .dark ? 0.54 : 0.46), lineWidth: 1))
            .padding(18)
        }
        .frame(width: 430, height: 680)
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(V08Text.text("category", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))
            TextField(V08Text.text("categoryPlaceholder", language), text: $category)
                .font(.system(size: 13))
                .padding(8)
                .background(fieldBackground)
                .overlay(fieldBorder)
        }
    }

    private var linkField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(V08Text.text("link", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))
            TextField(V08Text.text("linkPlaceholder", language), text: $link)
                .font(.system(size: 13))
                .padding(8)
                .background(fieldBackground)
                .overlay(fieldBorder)
        }
    }

    private var repeatRuleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(V08Text.text("repeat", language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RadixPalette.faintText(colorScheme))

            Picker("", selection: $repeatRule) {
                ForEach(RepeatRule.allCases) { rule in
                    Text(localizedRepeatRule(rule)).tag(rule)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(6)
            .background(fieldBackground)
            .overlay(fieldBorder)

            if repeatRule == .customDays {
                TextField(V08Text.text("repeatCustomDays", language), value: $repeatCustomDays, format: .number)
                    .font(.system(size: 13))
                    .padding(6)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
            }
        }
    }

    private var archiveToggle: some View {
        Toggle(isOn: $isArchived) {
            Text(isArchived ? V08Text.text("restore", language) : V08Text.text("archive", language))
        }
        .toggleStyle(.switch)
        .padding(8)
    }

    private func localizedRepeatRule(_ rule: RepeatRule) -> String {
        switch rule {
        case .none: return V08Text.text("none", language)
        case .monthly: return V08Text.text("monthly", language)
        case .quarterly: return V08Text.text("quarterly", language)
        case .yearly: return V08Text.text("yearly", language)
        case .customDays: return V08Text.text("customDays", language)
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        onDone(.save(
            name: trimmedName,
            expiryDate: finalExpiryDate,
            note: trimmedNote,
            reminderOffsets: parsedReminderOffsets,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            link: link.trimmingCharacters(in: .whitespacesAndNewlines),
            isArchived: isArchived,
            repeatRule: repeatRule,
            repeatCustomDays: repeatCustomDays
        ))
        dismiss()
    }
}
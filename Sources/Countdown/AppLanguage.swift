import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case spanish = "es"
    case hindi = "hi"
    case arabic = "ar"
    case french = "fr"
    case bengali = "bn"
    case portuguese = "pt"
    case russian = "ru"
    case japanese = "ja"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .simplifiedChinese: return "简体中文"
        case .english: return "English"
        case .spanish: return "Español"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        case .french: return "Français"
        case .bengali: return "বাংলা"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .japanese: return "日本語"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .simplifiedChinese: return "zh_Hans_CN"
        case .english: return "en_US"
        case .spanish: return "es_ES"
        case .hindi: return "hi_IN"
        case .arabic: return "ar"
        case .french: return "fr_FR"
        case .bengali: return "bn_BD"
        case .portuguese: return "pt_BR"
        case .russian: return "ru_RU"
        case .japanese: return "ja_JP"
        }
    }

    static func current(from rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .simplifiedChinese
    }
}

enum L10n {
    static func text(_ key: String, _ language: AppLanguage) -> String {
        strings[language]?[key] ?? strings[.english]?[key] ?? key
    }

    static func daysValue(_ days: Int, _ language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            return "\(days) 天"
        case .english:
            return days == 1 ? "1 day" : "\(days) days"
        case .spanish:
            return days == 1 ? "1 día" : "\(days) días"
        case .hindi:
            return "\(days) दिन"
        case .arabic:
            return "\(days) يوم"
        case .french:
            return days == 1 ? "1 jour" : "\(days) jours"
        case .bengali:
            return "\(days) দিন"
        case .portuguese:
            return days == 1 ? "1 dia" : "\(days) dias"
        case .russian:
            return "\(days) дн."
        case .japanese:
            return "\(days)日"
        }
    }

    static func barkBody(itemName: String, daysUntilExpiry: Int, language: AppLanguage) -> String {
        if daysUntilExpiry == 0 {
            return String(format: text("barkDueToday", language), itemName)
        }
        return String(format: text("barkDueInDays", language), itemName, daysUntilExpiry)
    }

    private static let strings: [AppLanguage: [String: String]] = [
        .simplifiedChinese: [
            "cards": "卡片", "adjust": "调整", "done": "完成", "near": "临近", "far": "较远", "settings": "设置",
            "addHelp": "新增", "edit": "编辑", "delete": "删除", "itemName": "项目名称", "itemPlaceholder": "例如：会员续费、证件到期",
            "daysMode": "天数", "dateMode": "日期", "remainingDays": "剩余天数", "expiryDate": "到期日期", "due": "到期", "remaining": "剩余",
            "today": "今天", "cancel": "取消", "add": "添加", "save": "保存", "noItems": "还没有项目", "emptyHint": "点击加号添加第一个到期项目。",
            "pushSubtitle": "Bark 到期推送", "language": "语言", "enableBark": "启用 Bark 推送", "runtimeCheck": "应用运行时检查到期项目",
            "barkAddress": "Bark 推送地址", "barkAddressPlaceholder": "https://api.day.app/你的Key", "barkAddressHelp": "填写 Bark App 里复制的基础地址，格式如 https://api.day.app/你的Key",
            "pushTiming": "推送时间", "sevenDaysBefore": "到期前 7 天", "sevenDaysSubtitle": "剩余 7 天时推送项目名称", "dueToday": "到期当天", "dueTodaySubtitle": "剩余 0 天时推送项目名称",
            "testPush": "测试推送", "dedupeHint": "推送记录会去重，同一项目同一到期日不会重复发送。", "testIdle": "发送一条测试消息", "testSending": "发送中...", "testSuccess": "已发送", "testFailed": "发送失败，请检查地址",
            "testItem": "测试项目", "barkDueToday": "%@ 今天到期", "barkDueInDays": "%@ %d 天后到期",
        ],
        .english: [
            "cards": "Cards", "adjust": "Arrange", "done": "Done", "near": "Soon", "far": "Later", "settings": "Settings",
            "addHelp": "Add", "edit": "Edit", "delete": "Delete", "itemName": "Item name", "itemPlaceholder": "e.g. membership, document renewal",
            "daysMode": "Days", "dateMode": "Date", "remainingDays": "Days remaining", "expiryDate": "Expiry date", "due": "Due", "remaining": "Left",
            "today": "Today", "cancel": "Cancel", "add": "Add", "save": "Save", "noItems": "No items yet", "emptyHint": "Use the plus button to add your first expiry date.",
            "pushSubtitle": "Bark expiry push", "language": "Language", "enableBark": "Enable Bark push", "runtimeCheck": "Check due items while the app is running",
            "barkAddress": "Bark push URL", "barkAddressPlaceholder": "https://api.day.app/your-key", "barkAddressHelp": "Paste the base URL copied from Bark, for example https://api.day.app/your-key",
            "pushTiming": "Push timing", "sevenDaysBefore": "7 days before", "sevenDaysSubtitle": "Send the item name when 7 days remain", "dueToday": "Due day", "dueTodaySubtitle": "Send the item name when 0 days remain",
            "testPush": "Test push", "dedupeHint": "Pushes are deduplicated. The same item and due date will not be sent twice.", "testIdle": "Send a test message", "testSending": "Sending...", "testSuccess": "Sent", "testFailed": "Failed. Check the URL",
            "testItem": "Test item", "barkDueToday": "%@ is due today", "barkDueInDays": "%@ is due in %d days",
        ],
        .spanish: [
            "cards": "Tarjetas", "adjust": "Ordenar", "done": "Listo", "near": "Pronto", "far": "Luego", "settings": "Ajustes",
            "addHelp": "Añadir", "edit": "Editar", "delete": "Eliminar", "itemName": "Nombre", "itemPlaceholder": "Ej.: membresía, documento",
            "daysMode": "Días", "dateMode": "Fecha", "remainingDays": "Días restantes", "expiryDate": "Fecha límite", "due": "Vence", "remaining": "Resta",
            "today": "Hoy", "cancel": "Cancelar", "add": "Añadir", "save": "Guardar", "noItems": "Sin elementos", "emptyHint": "Usa el botón + para añadir una fecha.",
            "pushSubtitle": "Avisos Bark", "language": "Idioma", "enableBark": "Activar Bark", "runtimeCheck": "Comprobar vencimientos con la app abierta",
            "barkAddress": "URL de Bark", "barkAddressPlaceholder": "https://api.day.app/tu-clave", "barkAddressHelp": "Pega la URL base copiada de Bark.",
            "pushTiming": "Momento", "sevenDaysBefore": "7 días antes", "sevenDaysSubtitle": "Enviar el nombre cuando queden 7 días", "dueToday": "Día de vencimiento", "dueTodaySubtitle": "Enviar el nombre cuando queden 0 días",
            "testPush": "Probar", "dedupeHint": "Los avisos se deduplican por elemento y fecha.", "testIdle": "Enviar mensaje de prueba", "testSending": "Enviando...", "testSuccess": "Enviado", "testFailed": "Falló. Revisa la URL",
            "testItem": "Elemento de prueba", "barkDueToday": "%@ vence hoy", "barkDueInDays": "%@ vence en %d días",
        ],
        .hindi: [
            "cards": "कार्ड", "adjust": "क्रम", "done": "पूर्ण", "near": "जल्द", "far": "बाद", "settings": "सेटिंग",
            "addHelp": "जोड़ें", "edit": "संपादित", "delete": "हटाएं", "itemName": "आइटम नाम", "itemPlaceholder": "जैसे: सदस्यता, दस्तावेज़",
            "daysMode": "दिन", "dateMode": "तारीख", "remainingDays": "शेष दिन", "expiryDate": "अंतिम तारीख", "due": "देय", "remaining": "शेष",
            "today": "आज", "cancel": "रद्द", "add": "जोड़ें", "save": "सहेजें", "noItems": "कोई आइटम नहीं", "emptyHint": "पहला आइटम जोड़ने के लिए + दबाएं।",
            "pushSubtitle": "Bark रिमाइंडर", "language": "भाषा", "enableBark": "Bark चालू करें", "runtimeCheck": "ऐप चलते समय देय आइटम जांचें",
            "barkAddress": "Bark URL", "barkAddressPlaceholder": "https://api.day.app/your-key", "barkAddressHelp": "Bark से कॉपी किया आधार URL पेस्ट करें।",
            "pushTiming": "समय", "sevenDaysBefore": "7 दिन पहले", "sevenDaysSubtitle": "7 दिन शेष होने पर नाम भेजें", "dueToday": "देय दिन", "dueTodaySubtitle": "0 दिन शेष होने पर नाम भेजें",
            "testPush": "टेस्ट", "dedupeHint": "एक ही आइटम और तारीख दोबारा नहीं भेजी जाएगी।", "testIdle": "टेस्ट संदेश भेजें", "testSending": "भेज रहा है...", "testSuccess": "भेजा गया", "testFailed": "विफल। URL जांचें",
            "testItem": "टेस्ट आइटम", "barkDueToday": "%@ आज देय है", "barkDueInDays": "%@ %d दिन में देय है",
        ],
        .arabic: [
            "cards": "بطاقات", "adjust": "ترتيب", "done": "تم", "near": "قريب", "far": "لاحق", "settings": "الإعدادات",
            "addHelp": "إضافة", "edit": "تعديل", "delete": "حذف", "itemName": "اسم العنصر", "itemPlaceholder": "مثال: اشتراك، مستند",
            "daysMode": "أيام", "dateMode": "تاريخ", "remainingDays": "الأيام المتبقية", "expiryDate": "تاريخ الانتهاء", "due": "ينتهي", "remaining": "متبقٍ",
            "today": "اليوم", "cancel": "إلغاء", "add": "إضافة", "save": "حفظ", "noItems": "لا توجد عناصر", "emptyHint": "استخدم زر + لإضافة أول تاريخ.",
            "pushSubtitle": "تنبيهات Bark", "language": "اللغة", "enableBark": "تفعيل Bark", "runtimeCheck": "فحص العناصر أثناء تشغيل التطبيق",
            "barkAddress": "رابط Bark", "barkAddressPlaceholder": "https://api.day.app/your-key", "barkAddressHelp": "الصق الرابط الأساسي المنسوخ من Bark.",
            "pushTiming": "وقت التنبيه", "sevenDaysBefore": "قبل 7 أيام", "sevenDaysSubtitle": "إرسال الاسم عند بقاء 7 أيام", "dueToday": "يوم الانتهاء", "dueTodaySubtitle": "إرسال الاسم عند بقاء 0 يوم",
            "testPush": "اختبار", "dedupeHint": "لن يتكرر إرسال نفس العنصر ونفس التاريخ.", "testIdle": "إرسال رسالة اختبار", "testSending": "جارٍ الإرسال...", "testSuccess": "تم الإرسال", "testFailed": "فشل. تحقق من الرابط",
            "testItem": "عنصر اختبار", "barkDueToday": "%@ ينتهي اليوم", "barkDueInDays": "%@ ينتهي بعد %d يوم",
        ],
        .french: [
            "cards": "Cartes", "adjust": "Ranger", "done": "Terminé", "near": "Bientôt", "far": "Plus tard", "settings": "Réglages",
            "addHelp": "Ajouter", "edit": "Modifier", "delete": "Supprimer", "itemName": "Nom", "itemPlaceholder": "Ex. abonnement, document",
            "daysMode": "Jours", "dateMode": "Date", "remainingDays": "Jours restants", "expiryDate": "Date d'échéance", "due": "Échéance", "remaining": "Reste",
            "today": "Aujourd'hui", "cancel": "Annuler", "add": "Ajouter", "save": "Enregistrer", "noItems": "Aucun élément", "emptyHint": "Utilisez + pour ajouter une date.",
            "pushSubtitle": "Alertes Bark", "language": "Langue", "enableBark": "Activer Bark", "runtimeCheck": "Vérifier les échéances quand l'app tourne",
            "barkAddress": "URL Bark", "barkAddressPlaceholder": "https://api.day.app/votre-cle", "barkAddressHelp": "Collez l'URL de base copiée depuis Bark.",
            "pushTiming": "Moment", "sevenDaysBefore": "7 jours avant", "sevenDaysSubtitle": "Envoyer le nom quand il reste 7 jours", "dueToday": "Jour J", "dueTodaySubtitle": "Envoyer le nom quand il reste 0 jour",
            "testPush": "Tester", "dedupeHint": "Les alertes sont dédupliquées par élément et date.", "testIdle": "Envoyer un message test", "testSending": "Envoi...", "testSuccess": "Envoyé", "testFailed": "Échec. Vérifiez l'URL",
            "testItem": "Élément test", "barkDueToday": "%@ arrive à échéance aujourd'hui", "barkDueInDays": "%@ arrive à échéance dans %d jours",
        ],
        .bengali: [
            "cards": "কার্ড", "adjust": "সাজান", "done": "শেষ", "near": "শিগগির", "far": "পরে", "settings": "সেটিংস",
            "addHelp": "যোগ", "edit": "সম্পাদনা", "delete": "মুছুন", "itemName": "আইটেমের নাম", "itemPlaceholder": "যেমন: সদস্যতা, নথি",
            "daysMode": "দিন", "dateMode": "তারিখ", "remainingDays": "বাকি দিন", "expiryDate": "শেষ তারিখ", "due": "শেষ", "remaining": "বাকি",
            "today": "আজ", "cancel": "বাতিল", "add": "যোগ", "save": "সংরক্ষণ", "noItems": "কোনো আইটেম নেই", "emptyHint": "+ চাপুন প্রথম তারিখ যোগ করতে।",
            "pushSubtitle": "Bark রিমাইন্ডার", "language": "ভাষা", "enableBark": "Bark চালু করুন", "runtimeCheck": "অ্যাপ চালু থাকলে তারিখ পরীক্ষা করুন",
            "barkAddress": "Bark URL", "barkAddressPlaceholder": "https://api.day.app/your-key", "barkAddressHelp": "Bark থেকে কপি করা বেস URL পেস্ট করুন।",
            "pushTiming": "রিমাইন্ডার সময়", "sevenDaysBefore": "৭ দিন আগে", "sevenDaysSubtitle": "৭ দিন বাকি থাকলে নাম পাঠান", "dueToday": "শেষ দিন", "dueTodaySubtitle": "০ দিন বাকি থাকলে নাম পাঠান",
            "testPush": "পরীক্ষা", "dedupeHint": "একই আইটেম ও তারিখ আবার পাঠানো হবে না।", "testIdle": "টেস্ট বার্তা পাঠান", "testSending": "পাঠানো হচ্ছে...", "testSuccess": "পাঠানো হয়েছে", "testFailed": "ব্যর্থ। URL দেখুন",
            "testItem": "টেস্ট আইটেম", "barkDueToday": "%@ আজ শেষ", "barkDueInDays": "%@ %d দিনের মধ্যে শেষ",
        ],
        .portuguese: [
            "cards": "Cartões", "adjust": "Ordenar", "done": "Pronto", "near": "Próximo", "far": "Depois", "settings": "Ajustes",
            "addHelp": "Adicionar", "edit": "Editar", "delete": "Excluir", "itemName": "Nome", "itemPlaceholder": "Ex.: assinatura, documento",
            "daysMode": "Dias", "dateMode": "Data", "remainingDays": "Dias restantes", "expiryDate": "Data de vencimento", "due": "Vence", "remaining": "Restam",
            "today": "Hoje", "cancel": "Cancelar", "add": "Adicionar", "save": "Salvar", "noItems": "Sem itens", "emptyHint": "Use + para adicionar a primeira data.",
            "pushSubtitle": "Alertas Bark", "language": "Idioma", "enableBark": "Ativar Bark", "runtimeCheck": "Verificar vencimentos com o app aberto",
            "barkAddress": "URL Bark", "barkAddressPlaceholder": "https://api.day.app/sua-chave", "barkAddressHelp": "Cole a URL base copiada do Bark.",
            "pushTiming": "Horário", "sevenDaysBefore": "7 dias antes", "sevenDaysSubtitle": "Enviar o nome quando faltarem 7 dias", "dueToday": "No vencimento", "dueTodaySubtitle": "Enviar o nome quando faltarem 0 dias",
            "testPush": "Testar", "dedupeHint": "Alertas são deduplicados por item e data.", "testIdle": "Enviar mensagem de teste", "testSending": "Enviando...", "testSuccess": "Enviado", "testFailed": "Falhou. Verifique a URL",
            "testItem": "Item de teste", "barkDueToday": "%@ vence hoje", "barkDueInDays": "%@ vence em %d dias",
        ],
        .russian: [
            "cards": "Карты", "adjust": "Порядок", "done": "Готово", "near": "Скоро", "far": "Позже", "settings": "Настройки",
            "addHelp": "Добавить", "edit": "Изменить", "delete": "Удалить", "itemName": "Название", "itemPlaceholder": "Напр.: подписка, документ",
            "daysMode": "Дни", "dateMode": "Дата", "remainingDays": "Осталось дней", "expiryDate": "Дата срока", "due": "Срок", "remaining": "Осталось",
            "today": "Сегодня", "cancel": "Отмена", "add": "Добавить", "save": "Сохранить", "noItems": "Нет элементов", "emptyHint": "Нажмите +, чтобы добавить дату.",
            "pushSubtitle": "Уведомления Bark", "language": "Язык", "enableBark": "Включить Bark", "runtimeCheck": "Проверять сроки, пока приложение открыто",
            "barkAddress": "URL Bark", "barkAddressPlaceholder": "https://api.day.app/your-key", "barkAddressHelp": "Вставьте базовый URL из Bark.",
            "pushTiming": "Время", "sevenDaysBefore": "За 7 дней", "sevenDaysSubtitle": "Отправлять имя за 7 дней", "dueToday": "В день срока", "dueTodaySubtitle": "Отправлять имя при 0 днях",
            "testPush": "Тест", "dedupeHint": "Повторы для того же элемента и даты не отправляются.", "testIdle": "Отправить тест", "testSending": "Отправка...", "testSuccess": "Отправлено", "testFailed": "Ошибка. Проверьте URL",
            "testItem": "Тестовый элемент", "barkDueToday": "%@ истекает сегодня", "barkDueInDays": "%@ истекает через %d дн.",
        ],
        .japanese: [
            "cards": "カード", "adjust": "並べ替え", "done": "完了", "near": "近い", "far": "遠い", "settings": "設定",
            "addHelp": "追加", "edit": "編集", "delete": "削除", "itemName": "項目名", "itemPlaceholder": "例: 会員更新、書類期限",
            "daysMode": "日数", "dateMode": "日付", "remainingDays": "残り日数", "expiryDate": "期限日", "due": "期限", "remaining": "残り",
            "today": "今日", "cancel": "キャンセル", "add": "追加", "save": "保存", "noItems": "項目はありません", "emptyHint": "+ ボタンで期限を追加します。",
            "pushSubtitle": "Bark 通知", "language": "言語", "enableBark": "Bark 通知を有効化", "runtimeCheck": "アプリ起動中に期限を確認",
            "barkAddress": "Bark URL", "barkAddressPlaceholder": "https://api.day.app/your-key", "barkAddressHelp": "Bark からコピーしたベース URL を貼り付けます。",
            "pushTiming": "通知タイミング", "sevenDaysBefore": "7日前", "sevenDaysSubtitle": "残り7日に項目名を通知", "dueToday": "期限当日", "dueTodaySubtitle": "残り0日に項目名を通知",
            "testPush": "テスト通知", "dedupeHint": "同じ項目と期限日は重複通知しません。", "testIdle": "テストメッセージを送信", "testSending": "送信中...", "testSuccess": "送信済み", "testFailed": "失敗。URLを確認",
            "testItem": "テスト項目", "barkDueToday": "%@ は今日が期限です", "barkDueInDays": "%@ は%d日後が期限です",
        ],
    ]
}

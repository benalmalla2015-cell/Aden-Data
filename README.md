# عدن داتا — Aden Data

<div align="center">
  <img src="assets/screenshots/home.png" width="240" alt="Home Screen"/>
</div>

> **حارسك الشخصي للإنترنت** — تطبيق ذكي يركّز كامل النطاق الترددي على تطبيق واحد تختاره.

---

## الفكرة

يستخدم **عدن داتا** خدمة VPN محلية (Local VPN) لمنع حركة بيانات الخلفية من التطبيقات غير الضرورية، مما يمنح التطبيق الذي اخترته سرعة قصوى على شبكات 3G/4G أو الواي فاي الضعيف.

**صفر خوادم خارجية · صفر تتبع · صفر إعلانات**

---

## المميزات

- 🛡️ **محرك VPN محلي** — مستخرج ومُحسَّن من [NetGuard](https://github.com/M66B/NetGuard)
- 🧠 **ذكاء اصطناعي خفيف** — TFLite يصنّف جودة الشبكة (GOOD / WEAK / CONGESTED)
- 📱 **واجهة عربية RTL** — Material 3 بخلفية بيضاء وأزرار زرقاء
- ⚡ **3 بروفايلات**: بيانات محدودة | واي فاي ضعيف | شفافية كاملة
- 🔋 **استهلاك منخفض** — ≤ 30 MB RAM، لا يعمل الـ AI إلا عند تغيير الشبكة

---

## المتطلبات

| الأداة | الإصدار |
|---|---|
| Flutter | 3.27+ |
| Dart | 3.6+ |
| Android | 5.0 (API 21) → 14 (API 34) |
| Java | 17 |

---

## البدء السريع

```bash
git clone https://github.com/benalmalla2015-cell/Aden-Data.git
cd Aden-Data

# إضافة ملف النموذج (انظر قسم TFLite)
cp path/to/net_quality.tflite assets/models/

# تثبيت الحزم
flutter pub get

# تشغيل على جهاز Android
flutter run

# بناء APK للإنتاج
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

---

## نموذج الذكاء الاصطناعي (TFLite)

الملف المطلوب: `assets/models/net_quality.tflite`

- **المدخلات**: `[latency_ms, jitter_ms, signal_dbm, link_speed_mbps, conn_type]`
- **المخرجات**: `[score_GOOD, score_WEAK, score_CONGESTED]`
- **الحجم المستهدف**: ≤ 50 KB (Decision Tree مُحوَّل لـ TFLite)
- **الاحتياطي**: إذا غاب الملف، يستخدم التطبيق تصنيفاً قواعدياً (Heuristic) تلقائياً

---

## بنية المشروع

```
lib/
├── main.dart
├── app/             (theme, router, l10n)
├── core/
│   ├── platform/    (MethodChannel → Kotlin)
│   ├── ai/          (NetworkQuality provider)
│   └── utils/       (VpnState, VpnProfile)
└── features/
    ├── home/        (الشاشة الرئيسية + المقياس)
    ├── apps_picker/ (قائمة التطبيقات)
    ├── profiles/    (البروفايلات الثلاثة)
    ├── disclosure/  (شاشة الشفافية)
    └── settings/    (الإعدادات)

android/.../kotlin/net/aden/data/
├── aden_data/MainActivity.kt
├── vpn/AdenVpnService.kt
├── vpn/PacketFilter.kt
├── ai/NetworkClassifier.kt
├── bridge/VpnBridge.kt
└── receiver/ConnectivityWatcher.kt
```

---

## سياسة Google Play

| المتطلب | الحالة |
|---|---|
| شاشة Disclosure عند أول تشغيل | ✅ |
| Foreground Notification أثناء VPN | ✅ |
| زر إيقاف كامل (Global Access) | ✅ |
| عدم الإرسال لخوادم خارجية | ✅ |
| Privacy Policy | ✅ GitHub Pages |

---

## المصادر

- **VPN Engine**: [M66B/NetGuard](https://github.com/M66B/NetGuard) (GPL-3.0)
- **AI Example**: [amitshekhariitbhu/Android-TensorFlow-Lite-Example](https://github.com/amitshekhariitbhu/Android-TensorFlow-Lite-Example) (Apache-2.0)

---

## الترخيص

MIT © 2026 Aden Data
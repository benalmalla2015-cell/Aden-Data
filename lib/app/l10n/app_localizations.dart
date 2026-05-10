import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];
}

abstract class S {
  static const appName = 'عدن داتا';
  static const tagline = 'حارسك الشخصي للإنترنت';
  static const startEngine = 'تشغيل المحرك';
  static const stopEngine = 'إيقاف المحرك';
  static const selectApp = 'اختر التطبيق المستهدف';
  static const changeApp = 'تغيير التطبيق';
  static const profiles = 'البروفايلات';
  static const profileCellular = 'بيانات محدودة';
  static const profileWeak = 'واي فاي ضعيف';
  static const profileGlobal = 'شفافية كاملة';
  static const profileCellularDesc = 'يركز النطاق الترددي لتطبيق واحد على شبكات 3G/4G';
  static const profileWeakDesc = 'يستقر الاتصال للتطبيق المختار على الواي فاي الضعيف';
  static const profileGlobalDesc = 'إيقاف المحرك — جميع التطبيقات تعمل بشكل طبيعي';
  static const networkQuality = 'جودة الشبكة';
  static const good = 'ممتازة';
  static const weak = 'ضعيفة';
  static const congested = 'مزدحمة';
  static const disclosureTitle = 'شفافية الاستخدام';
  static const disclosureBody =
      'يستخدم "عدن داتا" خدمة VPN محلية على جهازك فقط.\n\n'
      '• لا يتم إرسال أي بيانات إلى خوادم خارجية.\n'
      '• يقتصر عمل التطبيق على توجيه البيانات داخل جهازك.\n'
      '• يمكنك إيقاف المحرك في أي وقت من خلال بروفايل "شفافية كاملة".\n\n'
      'بالضغط على "موافق وابدأ" فإنك توافق على استخدام الـ VPN المحلي.';
  static const agree = 'موافق وابدأ';
  static const settings = 'الإعدادات';
  static const autoOptimize = 'تحسين تلقائي بالذكاء الاصطناعي';
  static const autoOptimizeDesc = 'يغير البروفايل تلقائياً بناءً على جودة الشبكة';
  static const searchApps = 'ابحث عن تطبيق...';
  static const selectTargetApp = 'اختر التطبيق المستهدف';
  static const confirm = 'تأكيد الاختيار';
  static const download = 'تنزيل';
  static const upload = 'رفع';
  static const latency = 'زمن الاستجابة';
  static const ms = 'ms';
  static const kbps = 'KB/s';
}

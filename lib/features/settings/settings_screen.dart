import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../main.dart';

final _autoOptimizeProvider = StateNotifierProvider<_BoolNotifier, bool>(
  (ref) => _BoolNotifier(ref.read(sharedPrefsProvider), 'auto_optimize'),
);

class _BoolNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final String _key;

  _BoolNotifier(this._prefs, this._key)
      : super(_prefs.getBool(_key) ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool(_key, state);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoOptimize = ref.watch(_autoOptimizeProvider);

    return Scaffold(
      backgroundColor: AdenColors.bg,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'الذكاء الاصطناعي'),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: AdenColors.primary,
            title: 'تحسين تلقائي بالذكاء الاصطناعي',
            subtitle: 'يغير البروفايل تلقائياً بناءً على جودة الشبكة',
            trailing: Switch(
              value: autoOptimize,
              onChanged: (_) =>
                  ref.read(_autoOptimizeProvider.notifier).toggle(),
              activeColor: AdenColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'حول التطبيق'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AdenColors.accent,
            title: 'الإصدار',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            iconColor: AdenColors.success,
            title: 'سياسة الخصوصية',
            subtitle: 'التطبيق لا يرسل أي بيانات خارجية',
          ),
          _SettingsTile(
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF25D366),
            title: 'تواصل معنا',
            subtitle: 'تطوير وبرمجة مؤسسة مدحت رشاد سعيد للحلول التقنية',
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://wa.me/967781115345');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AdenColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdenColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_rounded,
                        color: Color(0xFF25D366), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'واتساب',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AdenColors.textDark,
                          ),
                        ),
                        Text(
                          '781115345',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AdenColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      color: AdenColors.textMid, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:+967777511122');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AdenColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdenColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AdenColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_rounded,
                        color: AdenColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اتصال',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AdenColors.textDark,
                          ),
                        ),
                        Text(
                          '777511122',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AdenColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      color: AdenColors.textMid, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdenColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdenColors.divider),
            ),
            child: const Column(
              children: [
                Text(
                  'عدن داتا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AdenColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'بوابتك لإنترنت أسرع بلا حدود',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AdenColors.textMid,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AdenColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdenColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdenColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdenColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AdenColors.textMid,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

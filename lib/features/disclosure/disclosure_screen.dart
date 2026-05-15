import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../shared/widgets/aden_logo.dart';

class DisclosureScreen extends StatefulWidget {
  const DisclosureScreen({super.key});

  @override
  State<DisclosureScreen> createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends State<DisclosureScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('disclosure_accepted') == true) {
      if (mounted) context.go('/home');
    }
  }

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclosure_accepted', true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdenColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const AdenLogo(size: 72),
              const SizedBox(height: 24),
              const Text(
                'عدن داتا',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AdenColors.textDark,
                ),
              ),
              const Text(
                'بوابتك لإنترنت أسرع بلا حدود',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AdenColors.textMid,
                ),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AdenColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AdenColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'شفافية الاستخدام',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AdenColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildPoint(
                      Icons.shield_rounded,
                      'يعمل التطبيق كالمحرك الذكي داخل جهازك لتسريع اتصالك وتأمين بياناتك محلياً بنسبة 100%',
                    ),
                    _buildPoint(
                      Icons.cloud_off_rounded,
                      'لا يُرسَل أي بيانات إلى خوادم خارجية',
                    ),
                    _buildPoint(
                      Icons.toggle_on_rounded,
                      'يمكنك إيقاف المحرك في أي وقت',
                    ),
                    _buildPoint(
                      Icons.lock_rounded,
                      'خصوصيتك محفوظة — صفر تتبع وصفر إعلانات',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: AdenColors.primary,
                  ),
                  child: const Text(
                    'موافق وابدأ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'بالموافقة، تبدأ رحلتك مع الإنترنت الأسرع والأكثر أماناً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AdenColors.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AdenColors.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AdenColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

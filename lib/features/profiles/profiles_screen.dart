import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/vpn_state.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpn = ref.watch(vpnProvider);

    return Scaffold(
      backgroundColor: AdenColors.bg,
      appBar: AppBar(
        title: const Text('البروفايلات'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'اختر بروفايل يناسب حالة شبكتك',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: AdenColors.textMid,
            ),
          ),
          const SizedBox(height: 20),
          ...VpnProfile.values.map(
            (p) => _ProfileCard(
              profile: p,
              isActive: vpn.activeProfile == p,
              onTap: () => ref.read(vpnProvider.notifier).setProfile(p),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final VpnProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  IconData get _icon {
    switch (profile) {
      case VpnProfile.cellular:
        return Icons.signal_cellular_alt_rounded;
      case VpnProfile.weakWifi:
        return Icons.wifi_rounded;
      case VpnProfile.globalAccess:
        return Icons.public_rounded;
    }
  }

  Color get _accentColor {
    switch (profile) {
      case VpnProfile.cellular:
        return AdenColors.primary;
      case VpnProfile.weakWifi:
        return AdenColors.accent;
      case VpnProfile.globalAccess:
        return AdenColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : AdenColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AdenColors.primary : AdenColors.divider,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AdenColors.primary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, color: _accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AdenColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.description,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AdenColors.textMid,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AdenColors.primary,
                size: 24,
              )
            else
              const Icon(
                Icons.radio_button_unchecked_rounded,
                color: AdenColors.textMid,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/vpn_state.dart';

class ProfileChip extends StatelessWidget {
  final VpnProfile profile;
  final bool selected;
  final VoidCallback onTap;

  const ProfileChip({
    super.key,
    required this.profile,
    required this.selected,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AdenColors.gradient : null,
          color: selected ? null : AdenColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: selected ? Colors.transparent : AdenColors.divider,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AdenColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 16,
              color: selected ? Colors.white : AdenColors.textMid,
            ),
            const SizedBox(width: 6),
            Text(
              profile.label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AdenColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

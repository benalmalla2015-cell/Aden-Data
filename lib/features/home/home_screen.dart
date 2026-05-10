import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/vpn_state.dart';
import '../../shared/widgets/aden_logo.dart';
import '../../shared/widgets/profile_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpn   = ref.watch(vpnProvider);
    final stats = ref.watch(liveStatsProvider);

    return Scaffold(
      backgroundColor: AdenColors.bg,
      appBar: AppBar(
        backgroundColor: AdenColors.bg,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdenLogo(size: 32),
            const SizedBox(width: 10),
            const Text(
              'عدن داتا',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AdenColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, color: AdenColors.textDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _NetworkQualityBanner(),
            const SizedBox(height: 24),
            _SpeedGaugeCard(vpn: vpn, stats: stats),
            const SizedBox(height: 24),
            _TargetAppCard(vpn: vpn),
            const SizedBox(height: 24),
            _ProfilesSection(vpn: vpn, ref: ref),
            const SizedBox(height: 24),
            _BigToggleButton(vpn: vpn, ref: ref),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Reads aiState directly from live stats stream
final _aiStateFromStatsProvider = Provider.autoDispose<AiState>((ref) {
  final stats = ref.watch(liveStatsProvider);
  return stats.valueOrNull?.aiState ?? AiState.normal;
});

class _NetworkQualityBanner extends ConsumerStatefulWidget {
  const _NetworkQualityBanner();

  @override
  ConsumerState<_NetworkQualityBanner> createState() => _NetworkQualityBannerState();
}

class _NetworkQualityBannerState extends ConsumerState<_NetworkQualityBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(_aiStateFromStatsProvider);
    final color = aiState.gaugeColor;

    if (aiState.isPulsing) {
      _pulse.repeat(reverse: true);
      if (aiState == AiState.deepFreeze) {
        HapticFeedback.heavyImpact();
      }
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final opacity = aiState.isPulsing
            ? 0.08 + (_pulse.value * 0.12)
            : 0.08;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(aiState.isPulsing ? 0.5 + _pulse.value * 0.5 : 0.25),
              width: aiState.isPulsing ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                aiState == AiState.deepFreeze
                    ? Icons.emergency_rounded
                    : aiState == AiState.emergency
                        ? Icons.warning_amber_rounded
                        : Icons.wifi_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  aiState.banner,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  aiState.label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeedGaugeCard extends StatefulWidget {
  final VpnState vpn;
  final AsyncValue<VpnStats> stats;
  const _SpeedGaugeCard({required this.vpn, required this.stats});

  @override
  State<_SpeedGaugeCard> createState() => _SpeedGaugeCardState();
}

class _SpeedGaugeCardState extends State<_SpeedGaugeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downKbps = widget.stats.valueOrNull?.downKbps ?? 0;
    final upKbps   = widget.stats.valueOrNull?.upKbps ?? 0;
    final latency  = widget.stats.valueOrNull?.latencyMs ?? 0;
    final aiState  = widget.stats.valueOrNull?.aiState ?? AiState.normal;
    final gaugeColor = aiState.gaugeColor;
    final gaugeValue = (downKbps / 1024.0).clamp(0.0, 1.0);

    // Start/stop pulse animation
    if (aiState.isPulsing) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      if (_pulse.isAnimating) _pulse.stop();
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final scale = aiState.isPulsing ? 1.0 + _pulse.value * 0.04 : 1.0;
        final glowOpacity = aiState.isPulsing ? 0.1 + _pulse.value * 0.25 : 0.06;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdenColors.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: aiState.isPulsing
              ? gaugeColor.withOpacity(0.4 + _pulse.value * 0.6)
              : AdenColors.divider,
          width: aiState.isPulsing ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gaugeColor.withOpacity(glowOpacity),
            blurRadius: aiState.isPulsing ? 30 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Transform.scale(
            scale: scale,
            child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: SpeedGaugePainter(
                    value: gaugeValue,
                    primaryColor: gaugeColor,
                    bgColor: AdenColors.divider,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      downKbps.toStringAsFixed(0),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: gaugeColor,
                      ),
                    ),
                    Text(
                      'KB/s',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: gaugeColor.withOpacity(0.7),
                      ),
                    ),
                    if (aiState == AiState.deepFreeze)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC143C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'RESCUE',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFDC143C),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.arrow_downward_rounded,
                label: 'تنزيل',
                value: '${downKbps.toStringAsFixed(0)} KB/s',
                color: gaugeColor,
              ),
              _StatItem(
                icon: Icons.arrow_upward_rounded,
                label: 'رفع',
                value: '${upKbps.toStringAsFixed(0)} KB/s',
                color: AdenColors.accent,
              ),
              _StatItem(
                icon: Icons.timer_outlined,
                label: 'استجابة',
                value: '$latency ms',
                color: AdenColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AdenColors.textMid,
          ),
        ),
      ],
    );
  }
}

class _TargetAppCard extends ConsumerWidget {
  final VpnState vpn;
  const _TargetAppCard({required this.vpn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/apps'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdenColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AdenColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AdenColors.gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.apps_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التطبيق المستهدف',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AdenColors.textMid,
                    ),
                  ),
                  Text(
                    vpn.targetApp?.appName ?? 'اضغط لاختيار تطبيق',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AdenColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: AdenColors.textMid,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilesSection extends StatelessWidget {
  final VpnState vpn;
  final WidgetRef ref;
  const _ProfilesSection({required this.vpn, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر البروفايل',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AdenColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: VpnProfile.values.map((profile) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ProfileChip(
                  profile: profile,
                  selected: vpn.activeProfile == profile,
                  onTap: () => ref
                      .read(vpnProvider.notifier)
                      .setProfile(profile),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          vpn.activeProfile.description,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AdenColors.textMid,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _BigToggleButton extends StatelessWidget {
  final VpnState vpn;
  final WidgetRef ref;
  const _BigToggleButton({required this.vpn, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isGlobal = vpn.activeProfile == VpnProfile.globalAccess;
    final canActivate = !isGlobal;

    return GestureDetector(
      onTap: () => ref.read(vpnProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          gradient: vpn.isActive && canActivate ? AdenColors.gradient : null,
          color: vpn.isActive && canActivate
              ? null
              : isGlobal
                  ? AdenColors.surface
                  : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: vpn.isActive && canActivate
                ? Colors.transparent
                : AdenColors.primary.withOpacity(0.3),
          ),
          boxShadow: vpn.isActive && canActivate
              ? [
                  BoxShadow(
                    color: AdenColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: vpn.isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vpn.isActive && canActivate
                          ? Icons.shield_rounded
                          : Icons.shield_outlined,
                      color: vpn.isActive && canActivate
                          ? Colors.white
                          : AdenColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isGlobal
                          ? 'وضع الشفافية الكاملة'
                          : vpn.isActive
                              ? 'المحرك يعمل — اضغط للإيقاف'
                              : 'اضغط لتشغيل المحرك',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: vpn.isActive && canActivate
                            ? Colors.white
                            : AdenColors.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

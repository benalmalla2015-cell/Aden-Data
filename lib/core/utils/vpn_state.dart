import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/vpn_channel.dart';

// ── AI Network State ────────────────────────────────────────────────────────
enum AiState { normal, degraded, emergency, deepFreeze }

extension AiStateX on AiState {
  String get label {
    switch (this) {
      case AiState.normal:     return 'ممتازة';
      case AiState.degraded:   return 'ضعيفة';
      case AiState.emergency:  return 'طوارئ';
      case AiState.deepFreeze: return 'وضع الإنقاذ';
    }
  }

  Color get gaugeColor {
    switch (this) {
      case AiState.normal:     return const Color(0xFF10B981);
      case AiState.degraded:   return const Color(0xFFF59E0B);
      case AiState.emergency:  return const Color(0xFFF97316);
      case AiState.deepFreeze: return const Color(0xFFDC143C); // Crimson
    }
  }

  bool get isPulsing => this == AiState.deepFreeze || this == AiState.emergency;

  String get banner {
    switch (this) {
      case AiState.deepFreeze:
        return 'وضع الإنقاذ نشط — WhatsApp فقط';
      case AiState.emergency:
        return 'شبكة شبه ميتة — الرسائل فقط';
      case AiState.degraded:
        return 'شبكة ضعيفة — يتم تحسين الأداء';
      case AiState.normal:
        return 'الشبكة بحالة جيدة';
    }
  }

  static AiState fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'DEGRADED':    return AiState.degraded;
      case 'EMERGENCY':   return AiState.emergency;
      case 'DEEP_FREEZE': return AiState.deepFreeze;
      default:            return AiState.normal;
    }
  }
}

// ── VPN Profile ──────────────────────────────────────────────────────────────
enum VpnProfile { cellular, weakWifi, emergency, globalAccess }

extension VpnProfileX on VpnProfile {
  String get id {
    switch (this) {
      case VpnProfile.cellular:
        return 'CELLULAR';
      case VpnProfile.weakWifi:
        return 'WEAK_WIFI';
      case VpnProfile.emergency:
        return 'EMERGENCY';
      case VpnProfile.globalAccess:
        return 'GLOBAL';
    }
  }

  String get label {
    switch (this) {
      case VpnProfile.cellular:
        return 'بيانات محدودة';
      case VpnProfile.weakWifi:
        return 'واي فاي ضعيف';
      case VpnProfile.emergency:
        return 'وضع الطوارئ';
      case VpnProfile.globalAccess:
        return 'شفافية كاملة';
    }
  }

  String get description {
    switch (this) {
      case VpnProfile.cellular:
        return 'يركز النطاق الترددي على التطبيق المختار (3G/4G)';
      case VpnProfile.weakWifi:
        return 'يستقر الاتصال للتطبيق المختار على الواي فاي الضعيف';
      case VpnProfile.emergency:
        return 'وضع طوارئ — يقتل TCP الثقيل ويفتح UDP للرسائل فقط';
      case VpnProfile.globalAccess:
        return 'إيقاف المحرك — جميع التطبيقات تعمل بشكل طبيعي';
    }
  }
}

class VpnStats {
  final double downKbps;
  final double upKbps;
  final int latencyMs;
  final AiState aiState;

  const VpnStats({
    required this.downKbps,
    required this.upKbps,
    required this.latencyMs,
    this.aiState = AiState.normal,
  });

  factory VpnStats.fromMap(Map<String, dynamic> map) => VpnStats(
    downKbps: (map['down_kbps'] as num?)?.toDouble() ?? 0,
    upKbps: (map['up_kbps'] as num?)?.toDouble() ?? 0,
    latencyMs: (map['latency'] as num?)?.toInt() ?? 0,
    aiState: AiStateX.fromString(map['ai_state'] as String?),
  );
}

class VpnState {
  final bool isActive;
  final VpnProfile activeProfile;
  final AppInfo? targetApp;
  final bool isLoading;
  final AiState aiState;

  const VpnState({
    this.isActive = false,
    this.activeProfile = VpnProfile.globalAccess,
    this.targetApp,
    this.isLoading = false,
    this.aiState = AiState.normal,
  });

  VpnState copyWith({
    bool? isActive,
    VpnProfile? activeProfile,
    AppInfo? targetApp,
    bool? isLoading,
    AiState? aiState,
    bool clearTarget = false,
  }) =>
      VpnState(
        isActive: isActive ?? this.isActive,
        activeProfile: activeProfile ?? this.activeProfile,
        targetApp: clearTarget ? null : (targetApp ?? this.targetApp),
        isLoading: isLoading ?? this.isLoading,
        aiState: aiState ?? this.aiState,
      );
}

class VpnNotifier extends StateNotifier<VpnState> {
  VpnNotifier() : super(const VpnState());

  Future<void> toggle() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    if (state.isActive) {
      await VpnChannel.stopVpn();
      state = state.copyWith(isActive: false, isLoading: false);
    } else {
      if (state.activeProfile == VpnProfile.globalAccess) {
        await VpnChannel.stopVpn();
        state = state.copyWith(isActive: false, isLoading: false);
        return;
      }
      final packages = state.targetApp != null
          ? [state.targetApp!.packageName]
          : <String>[];
      final ok = await VpnChannel.startVpn(
        allowedPackages: packages,
        profile: state.activeProfile.id,
      );
      state = state.copyWith(isActive: ok, isLoading: false);
    }
  }

  void setProfile(VpnProfile profile) {
    if (profile == VpnProfile.globalAccess && state.isActive) {
      VpnChannel.stopVpn();
      state = state.copyWith(
        activeProfile: profile,
        isActive: false,
      );
    } else {
      state = state.copyWith(activeProfile: profile);
    }
  }

  void setTargetApp(AppInfo app) {
    state = state.copyWith(targetApp: app);
  }
}

final vpnProvider = StateNotifierProvider<VpnNotifier, VpnState>(
  (_) => VpnNotifier(),
);

final liveStatsProvider = StreamProvider.autoDispose<VpnStats>(
  (_) => VpnChannel.liveStats,
);

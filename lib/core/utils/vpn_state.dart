import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/vpn_channel.dart';

enum VpnProfile { cellular, weakWifi, globalAccess }

extension VpnProfileX on VpnProfile {
  String get id {
    switch (this) {
      case VpnProfile.cellular:
        return 'CELLULAR';
      case VpnProfile.weakWifi:
        return 'WEAK_WIFI';
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
      case VpnProfile.globalAccess:
        return 'إيقاف المحرك — جميع التطبيقات تعمل بشكل طبيعي';
    }
  }
}

class VpnState {
  final bool isActive;
  final VpnProfile activeProfile;
  final AppInfo? targetApp;
  final bool isLoading;

  const VpnState({
    this.isActive = false,
    this.activeProfile = VpnProfile.globalAccess,
    this.targetApp,
    this.isLoading = false,
  });

  VpnState copyWith({
    bool? isActive,
    VpnProfile? activeProfile,
    AppInfo? targetApp,
    bool? isLoading,
    bool clearTarget = false,
  }) =>
      VpnState(
        isActive: isActive ?? this.isActive,
        activeProfile: activeProfile ?? this.activeProfile,
        targetApp: clearTarget ? null : (targetApp ?? this.targetApp),
        isLoading: isLoading ?? this.isLoading,
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/vpn_channel.dart';

enum NetworkQuality { good, weak, congested }

extension NetworkQualityX on NetworkQuality {
  String get label {
    switch (this) {
      case NetworkQuality.good:
        return 'ممتازة';
      case NetworkQuality.weak:
        return 'ضعيفة';
      case NetworkQuality.congested:
        return 'مزدحمة';
    }
  }

  int get color {
    switch (this) {
      case NetworkQuality.good:
        return 0xFF10B981;
      case NetworkQuality.weak:
        return 0xFFF59E0B;
      case NetworkQuality.congested:
        return 0xFFEF4444;
    }
  }
}

NetworkQuality _parse(String raw) {
  switch (raw.toUpperCase()) {
    case 'WEAK':
      return NetworkQuality.weak;
    case 'CONGESTED':
      return NetworkQuality.congested;
    default:
      return NetworkQuality.good;
  }
}

final networkQualityProvider = FutureProvider.autoDispose<NetworkQuality>(
  (ref) async {
    final raw = await VpnChannel.classifyNetwork();
    return _parse(raw);
  },
);

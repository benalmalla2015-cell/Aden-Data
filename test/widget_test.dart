import 'package:flutter_test/flutter_test.dart';
import 'package:aden_data/core/utils/vpn_state.dart';

void main() {
  group('AiState', () {
    test('fromString parses all states', () {
      expect(AiStateX.fromString('NORMAL'),     AiState.normal);
      expect(AiStateX.fromString('DEGRADED'),   AiState.degraded);
      expect(AiStateX.fromString('EMERGENCY'),  AiState.emergency);
      expect(AiStateX.fromString('DEEP_FREEZE'), AiState.deepFreeze);
      expect(AiStateX.fromString(null),          AiState.normal);
    });

    test('deepFreeze isPulsing', () {
      expect(AiState.deepFreeze.isPulsing, isTrue);
      expect(AiState.normal.isPulsing,     isFalse);
    });
  });

  group('VpnStats', () {
    test('fromMap parses aiState', () {
      final stats = VpnStats.fromMap({
        'down_kbps': 15.0,
        'up_kbps': 5.0,
        'latency': 700,
        'ai_state': 'DEEP_FREEZE',
      });
      expect(stats.downKbps, 15.0);
      expect(stats.aiState, AiState.deepFreeze);
    });
  });
}

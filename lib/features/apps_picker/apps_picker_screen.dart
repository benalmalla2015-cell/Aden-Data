import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/platform/vpn_channel.dart';
import '../../core/utils/vpn_state.dart';

final _installedAppsProvider = FutureProvider.autoDispose<List<AppInfo>>(
  (_) => VpnChannel.getInstalledApps(),
);

final _searchQueryProvider = StateProvider.autoDispose<String>((_) => '');

class AppsPickerScreen extends ConsumerWidget {
  const AppsPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(_installedAppsProvider);
    final query = ref.watch(_searchQueryProvider);
    final currentTarget = ref.watch(vpnProvider).targetApp;

    return Scaffold(
      backgroundColor: AdenColors.bg,
      appBar: AppBar(
        title: const Text('اختر التطبيق المستهدف'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن تطبيق...',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AdenColors.textMid,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AdenColors.textMid),
                filled: true,
                fillColor: AdenColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AdenColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AdenColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AdenColors.primary, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: apps.when(
              data: (list) {
                final filtered = query.isEmpty
                    ? list
                    : list
                        .where((a) =>
                            a.appName
                                .toLowerCase()
                                .contains(query.toLowerCase()) ||
                            a.packageName
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد تطبيقات',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final app = filtered[i];
                    final isSelected = currentTarget?.packageName ==
                        app.packageName;
                    return _AppTile(
                      app: app,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(vpnProvider.notifier)
                            .setTargetApp(app);
                        context.pop();
                      },
                    );
                  },
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: AdenColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل التطبيقات...',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    ),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'حدث خطأ: $e',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final AppInfo app;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppTile({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : AdenColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AdenColors.primary : AdenColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _AppIcon(iconBase64: app.iconBase64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AdenColors.textDark,
                    ),
                  ),
                  Text(
                    app.packageName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AdenColors.textMid,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AdenColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String? iconBase64;
  const _AppIcon({this.iconBase64});

  @override
  Widget build(BuildContext context) {
    if (iconBase64 != null) {
      try {
        final bytes = base64Decode(iconBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            Uint8List.fromList(bytes),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AdenColors.gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.android_rounded, color: Colors.white, size: 26),
    );
  }
}

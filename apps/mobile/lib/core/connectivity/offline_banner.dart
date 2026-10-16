import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

/// Whether the phone has a network connection (Wi-Fi or mobile data).
/// A connection does not guarantee the internet works, so screens still
/// handle request failures themselves; this only drives the banner.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online).distinct();
});

/// Thin banner shown on every screen while offline. When the connection
/// comes back, [onReconnected] lets the app refresh its data.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child, this.onReconnected});

  final Widget child;
  final void Function(WidgetRef ref)? onReconnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(isOnlineProvider, (previous, next) {
      if (previous?.value == false && next.value == true) onReconnected?.call(ref);
    });
    final offline = ref.watch(isOnlineProvider).value == false;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: offline
              ? Material(
                  color: context.colors.inverseSurface,
                  child: SafeArea(
                    bottom: false,
                    child: Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.sm),
                        child: Row(children: [
                          Icon(Icons.wifi_off_rounded, size: 18, color: context.colors.onInverseSurface),
                          Gap.sm,
                          Expanded(
                            child: Text(
                              "You're offline. Some information may be out of date.",
                              style: context.text.labelMedium?.copyWith(color: context.colors.onInverseSurface),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          // The banner already covers the status bar while it is visible.
          child: offline ? MediaQuery.removePadding(context: context, removeTop: true, child: child) : child,
        ),
      ],
    );
  }
}

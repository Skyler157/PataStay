import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

/// Shows [child] only to active administrators. This is a UX convenience:
/// RLS policies and assert_admin() in the database are the real protection.
class AdminGate extends ConsumerWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(currentProfileProvider)) {
      AsyncData(:final value?) when value.isAdmin && !value.isSuspended => child,
      AsyncData() => Scaffold(
          body: MessageView(
            icon: Icons.lock_outline_rounded,
            title: 'Administrator access required',
            message: 'This account does not have access to the PataStay admin dashboard.',
            action: OutlinedButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ),
        ),
      AsyncError(:final error) => Scaffold(
          body: ErrorView(error: error, onRetry: () => ref.invalidate(currentProfileProvider)),
        ),
      _ => const Scaffold(body: LoadingView()),
    };
  }
}

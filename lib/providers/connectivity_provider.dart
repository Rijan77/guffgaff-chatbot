import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sessions_provider.dart';

/// True when the backend is reachable (not just has internet).
final backendReachableProvider = StateProvider<bool>((ref) => true);

/// Stream that updates [backendReachableProvider] on connectivity changes.
final connectivityListenerProvider = Provider<void>((ref) {
  Connectivity().onConnectivityChanged.listen((_) async {
    final api = ref.read(apiServiceProvider);
    final ok = await api.checkHealth();
    ref.read(backendReachableProvider.notifier).state = ok;
  });
});

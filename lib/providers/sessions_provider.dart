import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/session_model.dart';
import '../data/services/api_service.dart';
import '../data/services/local_storage_service.dart';

final apiServiceProvider = Provider<ApiService>((_) => ApiService());
final localStorageProvider = Provider<LocalStorageService>((_) => LocalStorageService());

// ── State ─────────────────────────────────────────────────────────────────────

class SessionsState {
  final List<SessionModel> sessions;
  final bool isLoading;
  final String? error;

  const SessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  SessionsState copyWith({
    List<SessionModel>? sessions,
    bool? isLoading,
    String? error,
  }) =>
      SessionsState(
        sessions: sessions ?? this.sessions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SessionsNotifier extends StateNotifier<SessionsState> {
  final ApiService _api;
  final LocalStorageService _local;

  SessionsNotifier(this._api, this._local) : super(const SessionsState());

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);

    // Always load local first — instant & works offline
    final localSessions = await _local.getSessions();
    state = state.copyWith(sessions: localSessions, isLoading: false);

    // Try to sync from backend
    try {
      final remote = await _api.getSessions();
      for (final s in remote) {
        await _local.upsertSession(s);
      }
      // Merge: remote is authoritative but preserve any local-only sessions
      final remoteIds = remote.map((s) => s.id).toSet();
      final localOnly = localSessions.where((s) => !remoteIds.contains(s.id)).toList();
      final merged = [...remote, ...localOnly];
      merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(sessions: merged, isLoading: false);
    } catch (_) {
      // Backend unreachable — local data is already shown, that's fine
    }
  }

  Future<SessionModel?> createSession() async {
    // Try backend first
    try {
      final session = await _api.createSession();
      await _local.upsertSession(session);
      state = state.copyWith(sessions: [session, ...state.sessions]);
      return session;
    } catch (_) {
      // Offline: create locally only
    }

    try {
      final session = await _local.createSession();
      state = state.copyWith(sessions: [session, ...state.sessions]);
      return session;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> renameSession(String sessionId, String title) async {
    await _local.renameSession(sessionId, title);
    state = state.copyWith(
      sessions: state.sessions.map((s) {
        return s.id == sessionId ? s.copyWith(title: title) : s;
      }).toList(),
    );
    try {
      await _api.renameSession(sessionId, title);
    } catch (_) {}
  }

  Future<void> deleteSession(String sessionId) async {
    await _local.deleteSession(sessionId);
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != sessionId).toList(),
    );
    try {
      await _api.deleteSession(sessionId);
    } catch (_) {}
  }

  void updateTitle(String sessionId, String title) {
    state = state.copyWith(
      sessions: state.sessions.map((s) {
        return s.id == sessionId ? s.copyWith(title: title) : s;
      }).toList(),
    );
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  return SessionsNotifier(
    ref.read(apiServiceProvider),
    ref.read(localStorageProvider),
  );
});

final currentSessionIdProvider = StateProvider<String?>((ref) => null);

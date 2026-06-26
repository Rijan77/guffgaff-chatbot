import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/message_model.dart';
import '../data/services/api_service.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/offline_chat_service.dart';
import 'sessions_provider.dart';

const _uuid = Uuid();

// ── State ─────────────────────────────────────────────────────────────────────

enum ChatStatus { idle, loading, streaming, error }

class ChatState {
  final List<MessageModel> messages;
  final ChatStatus status;
  final String? streamingId;
  final String? error;
  final bool isOffline;

  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.streamingId,
    this.error,
    this.isOffline = false,
  });

  bool get isStreaming => status == ChatStatus.streaming;
  bool get hasError => status == ChatStatus.error;

  ChatState copyWith({
    List<MessageModel>? messages,
    ChatStatus? status,
    String? streamingId,
    String? error,
    bool? isOffline,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        status: status ?? this.status,
        streamingId: streamingId,
        error: error,
        isOffline: isOffline ?? this.isOffline,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api;
  final LocalStorageService _local;
  final OfflineChatService _offline;
  final Ref _ref;

  ChatNotifier(this._api, this._local, this._offline, this._ref)
      : super(const ChatState());

  Future<void> loadMessages(String sessionId) async {
    state = state.copyWith(status: ChatStatus.loading, error: null);

    // Load local first (instant, offline-safe)
    final localMsgs = await _local.getMessages(sessionId);
    state = state.copyWith(messages: localMsgs, status: ChatStatus.idle);

    // Sync from backend if reachable
    try {
      final remote = await _api.getSessionMessages(sessionId);
      if (remote.isNotEmpty) {
        await _local.upsertMessages(remote, sessionId);
        state = state.copyWith(messages: remote, status: ChatStatus.idle);
      }
    } catch (_) {}
  }

  void clearMessages() => state = const ChatState();

  Future<void> sendMessage(String sessionId, String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = MessageModel(
      id: _uuid.v4(),
      role: 'user',
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    final assistantId = _uuid.v4();
    final placeholder = MessageModel(
      id: assistantId,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, placeholder],
      status: ChatStatus.streaming,
      streamingId: assistantId,
      error: null,
    );

    // Save user message locally
    await _local.insertMessage(userMsg, sessionId);

    // ── Try backend first ─────────────────────────────────────────────────
    final backendOk = await _tryBackendChat(sessionId, text, assistantId, userMsg);
    if (backendOk) return;

    // ── Offline fallback ──────────────────────────────────────────────────
    await _offlineResponse(sessionId, text, assistantId);
  }

  Future<bool> _tryBackendChat(
    String sessionId,
    String text,
    String assistantId,
    MessageModel userMsg,
  ) async {
    final history = state.messages
        .where((m) => m.id != userMsg.id && m.id != assistantId)
        .map((m) => <String, String>{'role': m.role, 'content': m.content})
        .toList();

    try {
      String accumulated = '';
      String finalSource = 'gemini';
      bool firstChunk = true;

      await for (final chunk in _api.streamChat(
        sessionId: sessionId,
        message: text.trim(),
        history: history,
      )) {
        if (chunk.done) break;
        accumulated += chunk.text;
        finalSource = chunk.source;

        if (firstChunk) {
          firstChunk = false;
          _ref.read(sessionsProvider.notifier).updateTitle(
                sessionId,
                text.trim().length > 60 ? text.trim().substring(0, 60) : text.trim(),
              );
        }

        final updated = MessageModel(
          id: assistantId,
          role: 'assistant',
          content: accumulated,
          source: finalSource,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(
          messages: state.messages.map((m) => m.id == assistantId ? updated : m).toList(),
        );
      }

      if (accumulated.isNotEmpty) {
        final finalMsg = MessageModel(
          id: assistantId,
          role: 'assistant',
          content: accumulated,
          source: finalSource,
          createdAt: DateTime.now(),
        );
        await _local.insertMessage(finalMsg, sessionId);
      }

      state = state.copyWith(
        status: ChatStatus.idle,
        streamingId: null,
        isOffline: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _offlineResponse(
    String sessionId,
    String text,
    String assistantId,
  ) async {
    // Try local manual data
    final answer = await _offline.findOfflineAnswer(text);

    final String content;
    final String source;

    if (answer != null) {
      content = answer;
      source = 'manual';
    } else {
      content =
          "I'm currently offline and couldn't find an answer in my local knowledge base. "
          "Please connect to the backend server to get AI-powered responses.";
      source = 'offline';
    }

    final offlineMsg = MessageModel(
      id: assistantId,
      role: 'assistant',
      content: content,
      source: source,
      createdAt: DateTime.now(),
    );

    await _local.insertMessage(offlineMsg, sessionId);

    state = state.copyWith(
      messages: state.messages
          .map((m) => m.id == assistantId ? offlineMsg : m)
          .toList(),
      status: ChatStatus.idle,
      streamingId: null,
      isOffline: answer == null,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.read(apiServiceProvider),
    ref.read(localStorageProvider),
    OfflineChatService(),
    ref,
  );
});

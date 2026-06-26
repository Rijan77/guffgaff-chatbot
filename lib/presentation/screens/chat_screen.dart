import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/chat_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/sessions_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sessions_drawer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionsProvider.notifier).loadSessions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _startNewChat() async {
    final session = await ref.read(sessionsProvider.notifier).createSession();
    if (session != null) {
      ref.read(currentSessionIdProvider.notifier).state = session.id;
      ref.read(chatProvider.notifier).clearMessages();
    } else {
      final error = ref.read(sessionsProvider).error;
      _showError(
        error?.contains('SocketException') == true || error?.contains('Connection refused') == true
            ? 'Cannot connect to backend. Make sure the server is running at ${AppConstants.baseUrl}'
            : 'Failed to create chat: ${error ?? 'Unknown error'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSessionId = ref.watch(currentSessionIdProvider);
    final chatState = ref.watch(chatProvider);
    final isBackendUp = ref.watch(backendReachableProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen(chatProvider.select((s) => s.messages.length), (_, __) => _scrollToBottom());

    // Start connectivity listener once
    ref.watch(connectivityListenerProvider);

    // Show session errors as snackbar
    ref.listen(sessionsProvider.select((s) => s.error), (_, error) {
      if (error != null) _showError(error);
    });

    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle(sessionId: currentSessionId),
        actions: [
          if (!isBackendUp)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Offline — using local data',
                child: Icon(Icons.cloud_off, color: cs.onSurfaceVariant, size: 20),
              ),
            ),
          if (currentSessionId != null)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New Chat',
              onPressed: _startNewChat,
            ),
        ],
      ),
      drawer: const SessionsDrawer(),
      body: currentSessionId == null
          ? _WelcomeView(onNewChat: _startNewChat)
          : Column(
              children: [
                if (!isBackendUp)
                  const _OfflineBanner(baseUrl: AppConstants.baseUrl),
                if (chatState.hasError)
                  _ErrorBanner(
                    message: chatState.error ?? 'Something went wrong.',
                    onDismiss: () => ref.read(chatProvider.notifier).clearMessages(),
                  ),

                Expanded(
                  child: chatState.status == ChatStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : chatState.messages.isEmpty
                          ? Center(
                              child: Text(
                                'Send a message to start chatting.',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
                              itemCount: chatState.messages.length,
                              itemBuilder: (_, i) {
                                final msg = chatState.messages[i];
                                return MessageBubble(
                                  key: ValueKey(msg.id),
                                  message: msg,
                                  isStreaming: msg.id == chatState.streamingId,
                                );
                              },
                            ),
                ),

                const Divider(height: 1),
                ChatInput(sessionId: currentSessionId),
              ],
            ),
    );
  }
}

// ── App bar title ─────────────────────────────────────────────────────────────

class _AppBarTitle extends ConsumerWidget {
  final String? sessionId;
  const _AppBarTitle({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionId == null) return const Text(AppConstants.appName);
    final sessions = ref.watch(sessionsProvider).sessions;
    final session = sessions.where((s) => s.id == sessionId).firstOrNull;
    return Text(
      session?.title ?? AppConstants.appName,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Welcome screen ────────────────────────────────────────────────────────────

class _WelcomeView extends StatefulWidget {
  final VoidCallback onNewChat;
  const _WelcomeView({required this.onNewChat});

  @override
  State<_WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<_WelcomeView> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('lib/assets/Logo.png', width: 72, height: 72),
          const SizedBox(height: 20),
          Text(
            AppConstants.appName,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your smart AI assistant',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    widget.onNewChat();
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) setState(() => _loading = false);
                  },
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add),
            label: Text(_loading ? 'Connecting…' : 'Start a New Chat'),
          ),
          const SizedBox(height: 16),
          Text(
            'Backend: ${AppConstants.baseUrl}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Offline banner ────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final String baseUrl;
  const _OfflineBanner({required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF424242),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — manual answers available. Start backend at $baseUrl for AI.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Theme.of(context).colorScheme.onErrorContainer,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

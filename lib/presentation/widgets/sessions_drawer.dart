import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/session_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/sessions_provider.dart';
import '../../providers/theme_provider.dart';

class SessionsDrawer extends ConsumerWidget {
  const SessionsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(sessionsProvider);
    final currentId = ref.watch(currentSessionIdProvider);
    final themeMode = ref.watch(themeModeProvider);
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(color: cs.surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('lib/assets/Logo.png', width: 36, height: 36),
                    const SizedBox(width: 10),
                    Text(
                      'GuffGaff AI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      tooltip: 'Toggle theme',
                      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _newChat(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Chat'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 38),
                  ),
                ),
              ],
            ),
          ),

          // Session list
          Expanded(
            child: sessionsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sessionsState.sessions.isEmpty
                    ? Center(
                        child: Text(
                          'No conversations yet.\nTap + New Chat to start.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sessionsState.sessions.length,
                        itemBuilder: (context, i) {
                          final session = sessionsState.sessions[i];
                          final isActive = session.id == currentId;
                          return _SessionTile(
                            session: session,
                            isActive: isActive,
                            onTap: () => _openSession(context, ref, session),
                            onRename: () => _renameDialog(context, ref, session),
                            onDelete: () => _deleteConfirm(context, ref, session, currentId),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _newChat(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final session = await ref.read(sessionsProvider.notifier).createSession();
    if (session != null) {
      ref.read(currentSessionIdProvider.notifier).state = session.id;
      ref.read(chatProvider.notifier).clearMessages();
    }
  }

  void _openSession(BuildContext context, WidgetRef ref, SessionModel session) {
    Navigator.of(context).pop();
    ref.read(currentSessionIdProvider.notifier).state = session.id;
    ref.read(chatProvider.notifier).loadMessages(session.id);
  }

  Future<void> _renameDialog(BuildContext context, WidgetRef ref, SessionModel session) async {
    final controller = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await ref.read(sessionsProvider.notifier).renameSession(session.id, newTitle);
    }
  }

  Future<void> _deleteConfirm(
    BuildContext context,
    WidgetRef ref,
    SessionModel session,
    String? currentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Delete "${session.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionsProvider.notifier).deleteSession(session.id);
      if (session.id == currentId) {
        ref.read(currentSessionIdProvider.notifier).state = null;
        ref.read(chatProvider.notifier).clearMessages();
      }
    }
  }
}

class _SessionTile extends StatelessWidget {
  final SessionModel session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = DateFormat('MMM d, HH:mm').format(session.updatedAt.toLocal());

    return ListTile(
      selected: isActive,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
      leading: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 20,
        color: isActive ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
        onSelected: (v) {
          if (v == 'rename') onRename();
          if (v == 'delete') onDelete();
        },
      ),
    );
  }
}

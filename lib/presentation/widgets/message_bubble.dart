import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../data/models/message_model.dart';
import 'source_badge.dart';
import 'typing_indicator.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isStreaming;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _UserBubble(message: message) : _AssistantBubble(message: message, isStreaming: isStreaming);
  }
}

// ── User bubble ───────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final MessageModel message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.content,
            style: TextStyle(color: cs.onPrimary, fontSize: 15, height: 1.4),
          ),
        ),
      ),
    );
  }
}

// ── Assistant bubble ──────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  final MessageModel message;
  final bool isStreaming;
  const _AssistantBubble({required this.message, required this.isStreaming});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252540) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isStreaming && message.content.isEmpty)
                const TypingIndicator()
              else if (message.content.isNotEmpty)
                MarkdownBody(
                  data: message.content,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    code: TextStyle(
                      backgroundColor: cs.surfaceContainerHighest,
                      fontSize: 13,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  selectable: true,
                ),
              if (!isStreaming && message.source != null) ...[
                const SizedBox(height: 8),
                SourceBadge(source: message.source!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

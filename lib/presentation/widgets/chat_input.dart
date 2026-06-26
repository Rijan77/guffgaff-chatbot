import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';

class ChatInput extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatInput({super.key, required this.sessionId});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(widget.sessionId, text);
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = ref.watch(chatProvider.select((s) => s.isStreaming));
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isStreaming,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Ask anything…',
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isStreaming
                  ? Container(
                      key: const ValueKey('loading'),
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.primary,
                      ),
                    )
                  : IconButton.filled(
                      key: const ValueKey('send'),
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

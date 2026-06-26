class ChatChunk {
  final String text;
  final String source;
  final bool done;

  const ChatChunk({
    required this.text,
    required this.source,
    required this.done,
  });

  factory ChatChunk.fromJson(Map<String, dynamic> json) => ChatChunk(
        text: json['text'] as String? ?? '',
        source: json['source'] as String? ?? 'gemini',
        done: json['done'] as bool? ?? false,
      );
}

class MessageModel {
  final String id;
  final String role; // "user" | "assistant"
  final String content;
  final String? source; // "manual" | "gemini+context" | "gemini"
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.source,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        source: json['source'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  MessageModel copyWith({String? content, String? source}) => MessageModel(
        id: id,
        role: role,
        content: content ?? this.content,
        source: source ?? this.source,
        createdAt: createdAt,
      );
}

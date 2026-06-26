class SessionModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  SessionModel copyWith({String? title, DateTime? updatedAt}) => SessionModel(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

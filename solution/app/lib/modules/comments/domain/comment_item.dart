// solution/app/lib/modules/comments/domain/comment_item.dart
// Value Object imutável de comentário de tarefa no app (D-07 / RF-12 / F5.1).
// IDs são UUID (String) — contrato OpenAPI (D-08).

import 'package:flutter/foundation.dart';

@immutable
final class CommentItem {
  const CommentItem({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String userId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      authorName: json['authorName'] as String? ?? 'Desconhecido',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'userId': userId,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          taskId == other.taskId &&
          userId == other.userId &&
          authorName == other.authorName &&
          content == other.content &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      taskId.hashCode ^
      userId.hashCode ^
      authorName.hashCode ^
      content.hashCode ^
      createdAt.hashCode;
}


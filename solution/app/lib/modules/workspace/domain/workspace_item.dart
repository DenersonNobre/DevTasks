// solution/app/lib/modules/workspace/domain/workspace_item.dart
// Value Object imutável de workspace no app (D-07 / RF-04 / RF-05 / D-02).

import 'package:meta/meta.dart';

@immutable
final class WorkspaceItem {
  const WorkspaceItem({
    required this.id,
    required this.name,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String name;
  final String role;
  final DateTime? createdAt;

  factory WorkspaceItem.fromJson(Map<String, dynamic> json) {
    return WorkspaceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'viewer',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ role.hashCode;
}


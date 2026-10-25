// solution/api/lib/modules/comments/domain/comment_content.dart
// Value Object de conteúdo de comentário (EPIC-05 · RF-12).

class CommentContent {
  const CommentContent._(this.value);

  final String value;

  static (CommentContent?, String?) parse(String? raw) {
    if (raw == null) {
      return (null, 'O conteúdo do comentário é obrigatório.');
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (null, 'O conteúdo do comentário não pode ser vazio.');
    }
    if (trimmed.length > 2000) {
      return (null, 'O conteúdo do comentário excede 2000 caracteres.');
    }
    return (CommentContent._(trimmed), null);
  }
}

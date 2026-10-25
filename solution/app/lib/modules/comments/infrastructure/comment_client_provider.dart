// solution/app/lib/modules/comments/infrastructure/comment_client_provider.dart
// Provedor Riverpod da porta ICommentClient (D-03 / D-07).

import 'package:devtasks_app/modules/comments/domain/comment_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'http_comment_client.dart';

final commentClientProvider = Provider<ICommentClient>((ref) {
  return HttpCommentClient();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../services/book_import_service.dart';
import '../services/book_service.dart';

final booksDaoProvider = Provider<BooksDao>(
  (ref) => ref.watch(appDatabaseProvider).booksDao,
);

final bookChaptersDaoProvider = Provider<BookChaptersDao>(
  (ref) => ref.watch(appDatabaseProvider).bookChaptersDao,
);

final booksStreamProvider = StreamProvider<List<BookRow>>(
  (ref) => ref.watch(booksDaoProvider).watchAll(),
);

final bookChaptersStreamProvider =
    StreamProvider.family<List<BookChapterRow>, int>(
      (ref, bookId) => ref.watch(bookChaptersDaoProvider).watchByBook(bookId),
    );

final bookServiceProvider = Provider<BookService>(
  (ref) => BookService(ref.watch(appDatabaseProvider)),
);

final bookImportServiceProvider = Provider<BookImportService>(
  (ref) => BookImportService(),
);

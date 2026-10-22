// 密码本服务：字段与备注经 SecretBox（AES-GCM）加密后入库，读取时解密。
import '../../../core/crypto/secret_box.dart';
import '../../../core/db/database.dart';
import 'package:drift/drift.dart' show Value;
import '../models/password_models.dart';

/// 解密后的条目视图。
class PasswordEntryView {
  const PasswordEntryView({
    required this.id,
    required this.name,
    required this.fields,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final List<PasswordField> fields;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PasswordService {
  PasswordService(this._db, this._crypto);

  final AppDatabase _db;
  final SecretBoxService _crypto;

  Stream<List<PasswordEntryRow>> watchAll() =>
      _db.passwordEntriesDao.watchAll();

  Future<PasswordEntryView?> load(int id) async {
    final row = await _db.passwordEntriesDao.byId(id);
    if (row == null) return null;
    final fieldsJson = await _crypto.decrypt(row.fieldsEnc);
    final note = row.noteEnc == null || row.noteEnc!.isEmpty
        ? ''
        : await _crypto.decrypt(row.noteEnc!);
    return PasswordEntryView(
      id: row.id,
      name: row.name,
      fields: decodeFieldsJson(fieldsJson),
      note: note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<int> create({
    required String name,
    required List<PasswordField> fields,
    String note = '',
  }) async {
    final now = DateTime.now();
    final fieldsEnc = await _crypto.encrypt(encodeFieldsJson(fields));
    final noteEnc = note.isEmpty ? null : await _crypto.encrypt(note);
    return _db.passwordEntriesDao.add(
      PasswordEntriesCompanion.insert(
        name: name.trim(),
        fieldsEnc: fieldsEnc,
        noteEnc: noteEnc == null ? const Value.absent() : Value(noteEnc),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> update(
    int id, {
    required String name,
    required List<PasswordField> fields,
    String note = '',
  }) async {
    final row = await _db.passwordEntriesDao.byId(id);
    if (row == null) throw StateError('条目不存在');
    final fieldsEnc = await _crypto.encrypt(encodeFieldsJson(fields));
    final noteEnc = note.isEmpty ? null : await _crypto.encrypt(note);
    await _db.passwordEntriesDao.updateRow(
      row.copyWith(
        name: name.trim(),
        fieldsEnc: fieldsEnc,
        noteEnc: Value(noteEnc),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> delete(int id) => _db.passwordEntriesDao.deleteById(id);
}

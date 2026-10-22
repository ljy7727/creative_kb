// 密码本服务单测：字段加解密入库、自定义字段、备注、更新与删除、明文不落库。
import 'package:creative_kb/core/crypto/secret_box.dart';
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/storage/secure_keys.dart';
import 'package:creative_kb/features/passwords/models/password_models.dart';
import 'package:creative_kb/features/passwords/services/password_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryKeyStore implements KeyStore {
  final Map<String, String> values = {};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

void main() {
  late AppDatabase db;
  late PasswordService service;

  setUp(() {
    db = AppDatabase.inMemory();
    service = PasswordService(
      db,
      SecretBoxService(store: _MemoryKeyStore()),
    );
  });

  tearDown(() => db.close());

  test('创建：自定义字段（账号/密码/验证号）与备注可完整读回', () async {
    final id = await service.create(
      name: '撸啊撸',
      fields: const [
        PasswordField(label: '账号', value: '123'),
        PasswordField(label: '密码', value: 'abc!@#'),
        PasswordField(label: '验证号', value: '928374'),
      ],
      note: '区服：艾欧尼亚',
    );
    final view = await service.load(id);
    expect(view, isNotNull);
    expect(view!.name, '撸啊撸');
    expect(view.fields.map((f) => f.label), ['账号', '密码', '验证号']);
    expect(view.fields[0].value, '123');
    expect(view.fields[1].value, 'abc!@#');
    expect(view.note, '区服：艾欧尼亚');
  });

  test('数据库内不落明文（字段与备注均为密文）', () async {
    final id = await service.create(
      name: 'test',
      fields: const [PasswordField(label: '密码', value: 'SuperSecret123')],
      note: 'also-secret-note',
    );
    final row = await db.passwordEntriesDao.byId(id);
    expect(row, isNotNull);
    expect(row!.fieldsEnc, isNot(contains('SuperSecret123')));
    expect(row.noteEnc, isNotNull);
    expect(row.noteEnc!, isNot(contains('also-secret-note')));
  });

  test('更新：改字段与备注，旧值不残留', () async {
    final id = await service.create(
      name: 'a',
      fields: const [PasswordField(label: '密码', value: 'old')],
    );
    await service.update(
      id,
      name: 'b',
      fields: const [PasswordField(label: '密码', value: 'new')],
      note: 'n',
    );
    final view = await service.load(id);
    expect(view!.name, 'b');
    expect(view.fields.single.value, 'new');
    expect(view.note, 'n');
    // 备注清空后应为空字符串。
    await service.update(
      id,
      name: 'b',
      fields: const [PasswordField(label: '密码', value: 'new')],
    );
    expect((await service.load(id))!.note, '');
  });

  test('删除：条目移除', () async {
    final id = await service.create(
      name: 'x',
      fields: const [PasswordField(label: '密码', value: 'v')],
    );
    await service.delete(id);
    expect(await service.load(id), isNull);
    expect(await db.passwordEntriesDao.getAll(), isEmpty);
  });
}

part of '../database.dart';

/// providers 表 DAO。
@DriftAccessor(tables: [Providers])
class ProvidersDao extends DatabaseAccessor<AppDatabase>
    with _$ProvidersDaoMixin {
  ProvidersDao(super.db);

  Stream<List<ProviderRow>> watchAll() =>
      (select(providers)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<List<ProviderRow>> getAll() => select(providers).get();

  Future<ProviderRow?> byId(int id) =>
      (select(providers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ProviderRow?> byKeyRef(String keyRef) => (select(
    providers,
  )..where((t) => t.keyRef.equals(keyRef))).getSingleOrNull();

  Future<int> add(ProvidersCompanion entry) => into(providers).insert(entry);

  Future<bool> updateRow(ProviderRow row) => update(providers).replace(row);

  Future<int> remove(int id) =>
      (delete(providers)..where((t) => t.id.equals(id))).go();
}

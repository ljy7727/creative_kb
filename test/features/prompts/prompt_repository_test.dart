import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/features/prompts/models/prompt_models.dart';
import 'package:creative_kb/features/prompts/services/prompt_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PromptRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = PromptRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create 写入首版本并回填 currentVersionId', () async {
    final id = await repository.create(
      title: '唐朝笏板描写',
      type: PromptType.novel,
      body: 'V1 正文',
      category: '器物',
    );
    final prompt = (await repository.byId(id))!;
    expect(prompt.title, '唐朝笏板描写');
    expect(prompt.body, 'V1 正文');
    final versions = await db.promptVersionsDao.byPrompt(id);
    expect(versions, hasLength(1));
    expect(versions.single.body, 'V1 正文');
    expect(versions.single.id, prompt.currentVersionId);
  });

  test('saveNewVersion 前移指针；rollbackToVersion 保留完整历史（版本回滚）', () async {
    final id = await repository.create(
      title: 't',
      type: PromptType.novel,
      body: 'V1',
    );
    await repository.saveNewVersion(promptId: id, body: 'V2', note: '扩写丰富');
    await repository.saveNewVersion(promptId: id, body: 'V3', note: '精简压缩');

    var versions = await db.promptVersionsDao.byPrompt(id);
    expect(versions.map((v) => v.body).toList(), ['V3', 'V2', 'V1']);
    expect((await repository.byId(id))!.body, 'V3');
    expect((await repository.byId(id))!.currentVersionId, versions.first.id);

    // 回滚到 V1：目标内容以新版本形式落库，历史链不丢（docs/02 模块C）。
    final v1 = versions.last;
    await repository.rollbackToVersion(promptId: id, versionId: v1.id);

    versions = await db.promptVersionsDao.byPrompt(id);
    expect(versions, hasLength(4));
    final prompt = (await repository.byId(id))!;
    expect(prompt.body, 'V1');
    expect(prompt.currentVersionId, versions.first.id);
    expect(versions.first.body, 'V1');
    expect(versions.first.note, contains('回滚自版本 #${v1.id}'));
  });

  test('rollbackToVersion 对不存在的版本抛 StateError', () async {
    final id = await repository.create(
      title: 't',
      type: PromptType.novel,
      body: 'V1',
    );
    await expectLater(
      repository.rollbackToVersion(promptId: id, versionId: 999),
      throwsA(isA<StateError>()),
    );
  });

  test('watchFiltered 按类型/分类/关键词过滤（分类与检索）', () async {
    await repository.create(
      title: '笏板场景',
      type: PromptType.novel,
      body: '水墨山河',
      category: '场景',
    );
    await repository.create(
      title: '赛博城市',
      type: PromptType.image,
      body: '霓虹雨夜',
    );
    await repository.create(
      title: '资料整理助手',
      type: PromptType.agent,
      body: '你是资料整理助手',
    );

    expect(
      await repository.watchFiltered(type: PromptType.image).first,
      hasLength(1),
    );
    expect(
      (await repository.watchFiltered(keyword: '笏板').first).single.title,
      '笏板场景',
    );
    expect(
      (await repository.watchFiltered(category: '场景').first).single.title,
      '笏板场景',
    );
    // 类型 + 关键词组合不命中时为空。
    expect(
      await repository
          .watchFiltered(type: PromptType.image, keyword: '笏板')
          .first,
      isEmpty,
    );
  });

  test('watchCategories 返回非空分类去重排序，null 不计入', () async {
    await repository.create(
      title: 'a',
      type: PromptType.novel,
      body: 'x',
      category: '场景',
    );
    await repository.create(
      title: 'b',
      type: PromptType.novel,
      body: 'x',
      category: '人物',
    );
    await repository.create(title: 'c', type: PromptType.novel, body: 'x');
    expect(await repository.watchCategories().first, ['人物', '场景']);
  });

  test('remove 连带删除全部版本', () async {
    final id = await repository.create(
      title: 't',
      type: PromptType.novel,
      body: 'V1',
    );
    await repository.saveNewVersion(promptId: id, body: 'V2');
    await repository.remove(id);
    expect(await repository.byId(id), isNull);
    expect(await db.promptVersionsDao.byPrompt(id), isEmpty);
  });

  test('变量表随 create/saveNewVersion 写入并可解析', () async {
    final id = await repository.create(
      title: 't',
      type: PromptType.novel,
      body: '{{主角}}出门',
      variables: const [PromptVariable(name: '主角', desc: '人物姓名')],
    );
    var prompt = (await repository.byId(id))!;
    expect(PromptVariable.decode(prompt.variables).single.name, '主角');

    await repository.saveNewVersion(
      promptId: id,
      body: '{{主角}}前往{{城市}}',
      variables: const [
        PromptVariable(name: '主角', desc: '人物姓名'),
        PromptVariable(name: '城市', desc: '地点'),
      ],
    );
    prompt = (await repository.byId(id))!;
    expect(
      PromptVariable.decode(prompt.variables).map((v) => v.name).toList(),
      ['主角', '城市'],
    );
  });
}

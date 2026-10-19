/// 内置 4 套分类 Schema（docs/02 D1），首启原样落盘到应用数据目录 schemas/。
/// 用户可直接编辑 JSON 文件扩展/修改，应用不做硬编码。
/// 结构：{id, name, matchKeywords[], baseSchema, fields:[{key,label,type,required}]}，
/// type 取值 enum|text|markdown|number；baseSchema=general 表示通用基础字段
/// （名称/标签/概述/正文 Markdown/可信度）为所有 Schema 公共部分。
abstract final class BuiltinSchemas {
  static const general = '''
{
  "id": "general",
  "name": "通用",
  "matchKeywords": [],
  "baseSchema": "general",
  "fields": []
}''';

  static const official = '''
{
  "id": "official",
  "name": "历史官职",
  "matchKeywords": ["官职", "官员", "朝廷", "品级", "衙门", "尚书", "侍郎", "总督", "巡抚"],
  "baseSchema": "general",
  "fields": [
    {"key": "dynasty", "label": "朝代", "type": "text", "required": true},
    {"key": "rank", "label": "品级", "type": "text", "required": false},
    {"key": "duties", "label": "职权", "type": "markdown", "required": false},
    {"key": "superior_subordinate", "label": "上下级", "type": "text", "required": false}
  ]
}''';

  static const treasure = '''
{
  "id": "treasure",
  "name": "仙侠宝物",
  "matchKeywords": ["法宝", "宝物", "法器", "灵器", "仙器", "神兵", "丹药", "炼器"],
  "baseSchema": "general",
  "fields": [
    {"key": "grade", "label": "品级", "type": "text", "required": false},
    {"key": "material", "label": "材质", "type": "text", "required": false},
    {"key": "effects", "label": "功效", "type": "markdown", "required": false},
    {"key": "refinement", "label": "炼制方式", "type": "text", "required": false},
    {"key": "rarity", "label": "稀有度", "type": "text", "required": false}
  ]
}''';

  static const sect = '''
{
  "id": "sect",
  "name": "宗门势力",
  "matchKeywords": ["宗门", "门派", "势力", "帮派", "仙门", "魔教", "教派"],
  "baseSchema": "general",
  "fields": [
    {"key": "hierarchy", "label": "层级", "type": "markdown", "required": false},
    {"key": "location", "label": "驻地", "type": "text", "required": false},
    {"key": "inheritance", "label": "传承功法", "type": "text", "required": false},
    {"key": "key_figures", "label": "核心人物", "type": "text", "required": false},
    {"key": "rival_forces", "label": "敌对势力", "type": "text", "required": false}
  ]
}''';

  /// 落盘顺序：通用在前，其余按 通用/官职/宝物/宗门。
  static const all = <({String id, String json})>[
    (id: 'general', json: general),
    (id: 'official', json: official),
    (id: 'treasure', json: treasure),
    (id: 'sect', json: sect),
  ];
}

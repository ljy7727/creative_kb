import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 应用数据目录（docs/03）：getApplicationSupportDirectory()/creative_kb/，
/// 其下为 app.db、schemas/、exports/。测试可注入临时目录（见 AppSeeder）。
Future<Directory> resolveAppDataDirectory() async {
  final base = await getApplicationSupportDirectory();
  return Directory(p.join(base.path, 'creative_kb'));
}

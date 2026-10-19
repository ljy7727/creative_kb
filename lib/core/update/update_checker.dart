// GitHub Releases 更新检查（docs/02 A6）：
// GET https://api.github.com/repos/{owner}/{repo}/releases/latest，
// semver 比对当前 pubspec version 与 tag；404 视为未发布（静默）。
// 桌面端「前往下载」打开 Release 页；Android 直接打开 .apk 资产链接。
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 语义化版本三元组（major.minor.patch；构建号不参与比较）。
class Semver {
  const Semver(this.major, this.minor, this.patch);

  /// 解析 `v1.2.3` / `1.2.3+4` / `1.2`；非法返回 null。
  static Semver? tryParse(String input) {
    var text = input.trim();
    if (text.startsWith('v') || text.startsWith('V')) text = text.substring(1);
    final plus = text.indexOf('+');
    if (plus >= 0) text = text.substring(0, plus);
    final match = RegExp(r'^(\d+)(?:\.(\d+))?(?:\.(\d+))?').firstMatch(text);
    if (match == null) return null;
    return Semver(
      int.parse(match.group(1)!),
      int.parse(match.group(2) ?? '0'),
      int.parse(match.group(3) ?? '0'),
    );
  }

  final int major;
  final int minor;
  final int patch;

  /// a>b 返回 1，a<b 返回 -1，相等 0。
  static int compare(Semver a, Semver b) {
    if (a.major != b.major) return a.major > b.major ? 1 : -1;
    if (a.minor != b.minor) return a.minor > b.minor ? 1 : -1;
    if (a.patch != b.patch) return a.patch > b.patch ? 1 : -1;
    return 0;
  }

  @override
  String toString() => '$major.$minor.$patch';
}

/// 一次检查的结果。latest==null 表示「未发布/不可达」，UI 静默或提示无更新。
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    this.latestVersion,
    this.tagName,
    this.releaseNotes,
    this.releasePageUrl,
    this.apkUrl,
  });

  final String currentVersion;

  /// 远端最新 semver（tag 解析失败时不给出，避免误报）。
  final Semver? latestVersion;
  final String? tagName;

  /// Release Notes 正文（markdown）。
  final String? releaseNotes;

  /// Release 网页（桌面端「前往下载」目标）。
  final String? releasePageUrl;

  /// .apk 资产直链（Android「前往下载」目标；无 apk 资产时为 null）。
  final String? apkUrl;

  bool get hasUpdate {
    final current = Semver.tryParse(currentVersion);
    final latest = latestVersion;
    if (current == null || latest == null) return false;
    return Semver.compare(latest, current) > 0;
  }
}

/// 当前应用版本（pubspec version，docs/03 第四节：唯一版本来源）。
/// 平台通道不可用（单元测试/纯 Dart 环境）时回落 0.0.0。
Future<String> resolveCurrentVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } catch (_) {
    return '0.0.0';
  }
}

/// GitHub Releases 检查器。网络异常类型化透出，由调用方决定提示方式。
class UpdateChecker {
  UpdateChecker({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Accept': 'application/vnd.github+json',
                // GitHub API 要求 User-Agent。
                'User-Agent': 'creative_kb-update-checker',
              },
              // 404 = 该仓库尚无 release（未发布），不作为异常抛出。
              validateStatus: (code) => code != null && code < 500,
            ),
          );

  final Dio _dio;

  /// 查询 {owner}/{repo} 的最新 release。
  /// 404 → 返回 latest=null（未发布，静默）；4xx/5xx → 抛 DioException。
  Future<UpdateCheckResult> check({
    required String owner,
    required String repo,
    required String currentVersion,
  }) async {
    final ownerTrim = owner.trim();
    final repoTrim = repo.trim();
    if (ownerTrim.isEmpty ||
        repoTrim.isEmpty ||
        (ownerTrim == 'yourname' && repoTrim == 'creative_kb')) {
      // 未配置真实仓库（默认占位）→ 视为未发布。
      return UpdateCheckResult(currentVersion: currentVersion);
    }
    final response = await _dio.get<Object>(
      'https://api.github.com/repos/$ownerTrim/$repoTrim/releases/latest',
    );
    if (response.statusCode == 404) {
      return UpdateCheckResult(currentVersion: currentVersion);
    }
    if (response.statusCode != 200) {
      throw DioException.connectionError(
        reason: 'GitHub API ${response.statusCode}',
        requestOptions: response.requestOptions,
      );
    }
    final data = response.data;
    if (data is! Map) {
      return UpdateCheckResult(currentVersion: currentVersion);
    }
    final tagName = (data['tag_name'] as String?) ?? '';
    final latest = Semver.tryParse(tagName);
    String? apkUrl;
    final assets = data['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is Map) {
          final name = (asset['name'] as String?) ?? '';
          final url = asset['browser_download_url'] as String?;
          if (url != null && name.toLowerCase().endsWith('.apk')) {
            apkUrl = url;
            break;
          }
        }
      }
    }
    return UpdateCheckResult(
      currentVersion: currentVersion,
      latestVersion: latest,
      tagName: tagName.isEmpty ? null : tagName,
      releaseNotes: data['body'] as String?,
      releasePageUrl: data['html_url'] as String?,
      apkUrl: apkUrl,
    );
  }

  /// 「前往下载」目标链接：Android 优先 .apk 资产，其余平台开 Release 页。
  static String downloadUrl(
    UpdateCheckResult result, {
    bool isAndroid = false,
  }) {
    if (isAndroid && result.apkUrl != null) return result.apkUrl!;
    return result.releasePageUrl ??
        result.apkUrl ??
        'https://github.com/releases';
  }

  /// 平台是否为 Android（launchUrl 决策用；测试可注入覆盖）。
  static bool get isAndroidPlatform =>
      defaultTargetPlatform == TargetPlatform.android;
}

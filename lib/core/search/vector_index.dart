import 'dart:math' as math;
import 'dart:typed_data';

/// 纯 Dart 向量数学（docs/00 D1：不引第三方；个人库规模内存暴力扫描）。
/// embeddings.vector 采用 float32 小端序列化（docs/01 第三节）。
abstract final class VectorCodec {
  /// float32 小端编码。
  static Uint8List encodeFloat32Le(List<double> vector) {
    final data = ByteData(vector.length * 4);
    for (var i = 0; i < vector.length; i++) {
      data.setFloat32(i * 4, vector[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }

  /// float32 小端解码；[dim] 缺省按字节数推算（bytes.length / 4）。
  static List<double> decodeFloat32Le(Uint8List bytes, {int? dim}) {
    final count = dim ?? bytes.length ~/ 4;
    if (count <= 0 || count * 4 > bytes.length) return const <double>[];
    final data = ByteData.sublistView(bytes);
    return List<double>.generate(
      count,
      (i) => data.getFloat32(i * 4, Endian.little),
    );
  }
}

/// 余弦相似度；维度不一致或存在零向量时返回 0（视为不相关，不抛异常）。
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.isEmpty || a.length != b.length) return 0;
  var dot = 0.0, normA = 0.0, normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}

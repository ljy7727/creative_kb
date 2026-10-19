import 'dart:typed_data';

import 'package:creative_kb/core/search/vector_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VectorCodec float32 小端编解码', () {
    test('编解码往返保持数值（1e-4 精度内）', () {
      final values = <double>[0.5, -1.25, 3.14159, 1024.0, -0.001];
      final bytes = VectorCodec.encodeFloat32Le(values);
      expect(bytes, hasLength(values.length * 4));

      final decoded = VectorCodec.decodeFloat32Le(bytes);
      expect(decoded, hasLength(values.length));
      for (var i = 0; i < values.length; i++) {
        expect(
          decoded[i],
          closeTo(values[i], 1e-4),
          reason: '第 $i 个分量 float32 精度往返',
        );
      }
    });

    test('小端字节序：首分量为 1.0 时前 4 字节为 00 00 80 3F', () {
      final bytes = VectorCodec.encodeFloat32Le(const [1.0]);
      expect(bytes, orderedEquals(<int>[0x00, 0x00, 0x80, 0x3F]));
    });

    test('dim 截断解码：4 分量字节按 dim=2 只解出前两个', () {
      final bytes = VectorCodec.encodeFloat32Le(const [1.0, 2.0, 3.0, 4.0]);
      final decoded = VectorCodec.decodeFloat32Le(bytes, dim: 2);
      expect(decoded, hasLength(2));
      expect(decoded[0], closeTo(1.0, 1e-6));
      expect(decoded[1], closeTo(2.0, 1e-6));
    });

    test('空向量与非整除字节数不抛异常', () {
      expect(VectorCodec.encodeFloat32Le(const <double>[]), isEmpty);
      expect(VectorCodec.decodeFloat32Le(Uint8List(0)), isEmpty);
      expect(VectorCodec.decodeFloat32Le(Uint8List(3)), isEmpty);
    });
  });

  group('余弦相似度（已知向量手算断言）', () {
    test('正交向量为 0', () {
      expect(cosineSimilarity(const [1, 0], const [0, 1]), 0);
    });

    test('同向向量为 1：(1,2,3) 与 (2,4,6)', () {
      expect(
        cosineSimilarity(const [1, 2, 3], const [2, 4, 6]),
        closeTo(1.0, 1e-9),
      );
    });

    test('反向向量为 -1', () {
      expect(
        cosineSimilarity(const [1, 0], const [-1, 0]),
        closeTo(-1.0, 1e-9),
      );
    });

    test('(2,1) 与 (1,2) = 4/5', () {
      expect(cosineSimilarity(const [2, 1], const [1, 2]), closeTo(0.8, 1e-9));
    });

    test('零向量或维度不一致返回 0（不抛异常）', () {
      expect(cosineSimilarity(const [0, 0], const [1, 2]), 0);
      expect(cosineSimilarity(const [1], const [1, 2]), 0);
      expect(cosineSimilarity(const <double>[], const [1]), 0);
    });
  });
}

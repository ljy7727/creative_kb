// 章节阅读页（v0.7）：Markdown 渲染、整页可滚动；
// 图片点击后进入全屏查看器（双指/滚轮缩放 + 拖动平移）。
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class BookReaderPage extends StatelessWidget {
  const BookReaderPage({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          // MarkdownBody 本身不滚动，必须包在滚动容器里（否则长章节无法下滑）。
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: MarkdownBody(
              data: content,
              selectable: true,
              sizedImageBuilder: (config) => _buildImage(context, config),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, MarkdownImageConfig config) {
    final source = config.uri.toString();
    final error = Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.broken_image_outlined, size: 36),
    );
    final Widget image;
    if (source.startsWith('assets/')) {
      image = Image.asset(
        source,
        fit: BoxFit.fitWidth,
        errorBuilder: (_, _, _) => error,
      );
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      image = Image.network(
        source,
        fit: BoxFit.fitWidth,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (_, _, _) => error,
      );
    } else {
      image = error;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () => _openViewer(context, source),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            image,
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.zoom_in,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 全屏图片查看器：InteractiveViewer 支持缩放与拖动。
  void _openViewer(BuildContext context, String source) {
    final Widget image = source.startsWith('assets/')
        ? Image.asset(source, errorBuilder: (_, _, _) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 48,
          ))
        : Image.network(
            source,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          );
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 6,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(child: image),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Text(
                '双指缩放 / 拖动查看',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

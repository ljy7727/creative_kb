// 章节阅读页（v0.4）：Markdown 渲染，支持 assets/ 内置图片与 http(s) 图片。
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
          child: MarkdownBody(
            data: content,
            selectable: true,
            sizedImageBuilder: (config) => _buildImage(context, config),
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
      image = Image.asset(source, fit: BoxFit.fitWidth, errorBuilder: (_, _, _) => error);
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
      child: image,
    );
  }
}

import 'dart:convert';

/// 将安全报告 Markdown 转为适合科大讯飞 TTS 朗读的纯文本。
///
/// 目标：与界面上用户看到的中文含义一致，去掉符号噪音，避免读「星号」「井号」等。
String plainTextForSecurityReportSpeech(String raw) {
  var text = raw.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty) return '';

  // 多轮去掉成对 Markdown（先 ** 再单 *，避免 lookbehind 兼容问题）
  for (var i = 0; i < 5; i++) {
    final before = text;
    text = text.replaceAll(RegExp(r'\*\*([\s\S]+?)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'__([\s\S]+?)__'), r'$1');
    text = text.replaceAll(RegExp(r'\*([^*\n]+?)\*'), r'$1');
    text = text.replaceAll(RegExp(r'_([^_\n]+?)_'), r'$1');
    if (text == before) break;
  }

  // 标题行：去掉行首 # 及空格
  text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

  // 链接 [文字](url) → 文字
  text = text.replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1');
  // 图片
  text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
  // 行内代码、代码块
  text = text.replaceAll(RegExp(r'`{3}[\s\S]*?`{3}'), ' ');
  text = text.replaceAll(RegExp(r'`([^`]*)`'), r'$1');

  // 表格：去掉 | --- | 分隔行，其它行把 | 换成逗号停顿感
  text = text.replaceAll(RegExp(r'^\|?[\s\-:|]+\|?\s*$', multiLine: true), '\n');
  text = text.replaceAll('|', '，');

  // 列表：行首 - * + 数字.
  text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
  text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

  // 去掉仍可能残留的 Markdown 符号（避免读「星号」「井号」）
  text = text.replaceAll(RegExp(r'[*_`#>]+'), '');

  // 合并空白
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return text.trim();
}

/// 讯飞单次请求文本需 &lt; 8000 字节（UTF-8），按字符边界安全切段。
List<String> chunkTextForTts(String text, {int maxBytes = 7200}) {
  final total = utf8.encode(text).length;
  if (total <= maxBytes) return [text];

  final out = <String>[];
  var rest = text;
  while (rest.isNotEmpty) {
    if (utf8.encode(rest).length <= maxBytes) {
      out.add(rest.trim());
      break;
    }
    var low = 1;
    var high = rest.length;
    var good = 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (utf8.encode(rest.substring(0, mid)).length <= maxBytes) {
        good = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    var cut = good;
    final head = rest.substring(0, cut);
    // 优先在句号、换行处断开，避免半句
    const seps = ['\n\n', '\n', '。', '！', '？', '；', '，', '、', ' '];
    for (final sep in seps) {
      final idx = head.lastIndexOf(sep);
      if (idx >= cut ~/ 3) {
        cut = idx + sep.length;
        break;
      }
    }
    final piece = rest.substring(0, cut).trim();
    if (piece.isEmpty) {
      // 单段极长无分隔符：硬切
      cut = good;
      out.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trimLeft();
      continue;
    }
    out.add(piece);
    rest = rest.substring(cut).trimLeft();
  }
  return out;
}

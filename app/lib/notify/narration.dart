// The model's own 「⏵ 在做什么」 line, pulled out of a reasoning or answer
// text. Moved here from lib/ui/chat/activity_copy.dart so the pet, the live
// activity and the activity strip all read the same parser: a line the pet
// shows must be the line the strip shows.
//
// Pure Dart, no Flutter imports: the tests cover it without a widget tree.

const narrationMaxColumns = 80;

bool _wide(int rune) =>
    (rune >= 0x1100 && rune <= 0x115F) ||
    (rune >= 0x2E80 && rune <= 0xA4CF) ||
    (rune >= 0xAC00 && rune <= 0xD7A3) ||
    (rune >= 0xF900 && rune <= 0xFAFF) ||
    (rune >= 0xFE30 && rune <= 0xFE4F) ||
    (rune >= 0xFF00 && rune <= 0xFF60) ||
    (rune >= 0xFFE0 && rune <= 0xFFE6) ||
    (rune >= 0x1F000 && rune <= 0x1FAFF) ||
    (rune >= 0x20000 && rune <= 0x3FFFD);

/// 模型写在正文里的最新一行 `⏵ 在做什么`;没有为 null。
///
/// `⏵` 必须在行首(句中的 `⏵` 是模型在*提*这个格式,不是在用它);只取到
/// 第一个句末标点,按显示宽度截到 80 列(约 40 个汉字),去掉控制字符。
String? extractNarration(String text) {
  // allMatches is lazy: checking isEmpty before last scans the first match twice.
  final match = RegExp(r'(?:^|\n)⏵[ \t]*([^\n⏵]*)').allMatches(text).lastOrNull;
  if (match == null) return null;
  var line = match.group(1)!.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  if (line.isEmpty) return null;
  // l10n:keep narration punctuation parser
  final end = RegExp(r'[。．!?！？;；]|\.(?=\s|$|[A-Z][a-z])').firstMatch(line);
  if (end != null) line = line.substring(0, end.end);

  var width = 0;
  var cut = line.length;
  var offset = 0;
  for (final rune in line.runes) {
    final w = _wide(rune) ? 2 : 1;
    if (width + w > narrationMaxColumns) {
      cut = offset;
      break;
    }
    width += w;
    offset += rune > 0xFFFF ? 2 : 1;
  }
  if (cut < line.length) {
    final head = line.substring(0, cut);
    final soft = [
      ' ',
      '，', // l10n:keep narration punctuation boundary
      '、', // l10n:keep narration punctuation boundary
      ',',
      ';',
      '；', // l10n:keep narration punctuation boundary
    ].map((needle) => head.lastIndexOf(needle)).fold<int>(-1, (a, b) => a > b ? a : b);
    line = soft > 0 ? head.substring(0, soft) : head;
  }
  // l10n:keep narration punctuation parser
  line = line.replaceFirst(RegExp(r'[。．.!！,，、;；]+$'), '').trim();
  return line.isEmpty ? null : line;
}

// What the model is thinking right now, as one short line for the pet's bubble.
//
// The text comes from the current conversation's last assistant step: the
// model's own `⏵ 在做什么` line (lib/notify/narration.dart), or — when the
// person asked for it — the last finished sentence of its reasoning. Both are
// re-read at most once per [PetPrefs.thoughtInterval] so a fast stream does not
// turn the bubble into a strobe.
//
// This is the only place a reasoning text leaves the chat transcript. It stays
// on the device: the pet overlay is a native window fed by the same channel as
// the bubbles, and nothing here is posted to a notification.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dsh_client/dsh_client.dart' show AssistantChatItem;

import '../notify/narration.dart';
import '../state/chat_state.dart';
import 'pet_mood.dart';
import 'pet_prefs.dart';
import 'pet_state.dart';

/// The conversation the pet speaks for, as far as its thought goes: the one on
/// screen, else a running top-level one.
PetTarget? petThoughtTarget(PetSignals signals) {
  final focus = signals.focus;
  if (focus != null) return PetTarget(focus.host, focus.sessionId);
  for (final run in signals.runs) {
    if (run.subagent) continue;
    return PetTarget(run.host, run.root);
  }
  return null;
}

/// The newest step still streaming, else the last one. Null when the
/// conversation is not loaded (a remote host the pet only sees events for).
String? petThoughtText(ChatState chat) {
  for (final item in chat.items.reversed) {
    if (item is! AssistantChatItem) continue;
    final reasoning = item.reasoning.trim();
    if (reasoning.isNotEmpty) return reasoning;
    // A streaming step with no reasoning yet: its own text is all there is.
    return item.streaming ? item.text : null;
  }
  return null;
}

/// The last finished sentence of [text]: what the model said last, whole.
/// Used only when 只显示 ⏵ 行 is off.
String? lastSentence(String text) {
  final clean = text.replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F\x7F]'), ' ').trimRight();
  if (clean.isEmpty) return null;
  final match = RegExp(r'[^\n。．!?！？]*[。．!?！？]').allMatches(clean).lastOrNull;
  final line = (match?.group(0) ?? clean.split('\n').last).trim();
  return line.isEmpty ? null : line;
}

/// Cut to [max] characters (not runes: a CJK char is one, an emoji is two).
String clipThought(String line, int max) {
  final chars = line.runes.toList();
  if (chars.length <= max) return line;
  return '${String.fromCharCodes(chars.take(max))}…';
}

/// The line the pet shows now, throttled: a new line is taken at most once per
/// [PetPrefs.thoughtInterval], and the one on screen stays until then. The
/// cache is module-level on purpose — one pet, one line, no extra provider.
String? petThoughtLine(Ref ref, PetSignals signals, PetPrefs prefs) {
  // Computed even with 显示思考 off: the pet's 「看思考」 shows the line once,
  // on demand. The switch only decides whether it rides along on its own.
  
  final target = petThoughtTarget(signals);
  if (target == null) return _keep();
  final raw = petThoughtText(ref.watch(chatProvider(target.sessionId)));
  final line = raw == null
      ? null
      : (prefs.thoughtOnlyNarration ? extractNarration(raw) : lastSentence(raw));
  if (line == null || line.isEmpty) return _keep();
  final next = clipThought(line, prefs.thoughtChars);
  if (next == _shown) return _shown;
  final now = DateTime.now();
  final shownAt = _shownAt;
  if (shownAt != null && now.difference(shownAt) < prefs.thoughtInterval) return _shown;
  _shown = next;
  _shownAt = now;
  return _shown;
}

String? _shown;
DateTime? _shownAt;

/// The line already on screen: a blank read (a new step starting) does not
/// blink it away, it waits for the next line to replace it.
String? _keep() => _shown;

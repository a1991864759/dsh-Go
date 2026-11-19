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

/// One assistant step's two halves: its reasoning and its own answer text. The
/// `⏵ 在做什么` line is written in the answer, the reasoning above it; which one
/// the pet shows depends on 只显示 ⏵ 概括行, so both come along.
typedef PetThoughtStep = ({String reasoning, String text});

/// The last [max] assistant steps, newest first. A turn writes several: the
/// reasoning comes first, the answer after it, and a streaming draft may have
/// neither yet — reading only the newest one shows nothing for most of a turn.
List<PetThoughtStep> petThoughtSteps(ChatState chat, {int max = 8}) {
  final out = <PetThoughtStep>[];
  for (final item in chat.items.reversed) {
    if (item is! AssistantChatItem) continue;
    final step = (reasoning: item.reasoning, text: item.text);
    if (step.reasoning.isEmpty && step.text.isEmpty) continue;
    out.add(step);
    if (out.length >= max) break;
  }
  return out;
}

/// A line for the pet out of [steps], newest first.
///
/// 只显示 ⏵ 行 looks for the model's own summary across the steps; when it wrote
/// none (it is not obliged to), the last finished sentence steps in rather than
/// leaving the bubble empty. The full mode prefers the reasoning, then the text.
String? petThoughtFrom(List<PetThoughtStep> steps, {required bool onlyNarration}) {
  if (steps.isEmpty) return null;
  String? first(String? Function(PetThoughtStep) pick) {
    for (final step in steps) {
      final line = pick(step);
      if (line != null && line.trim().isNotEmpty) return line.trim();
    }
    return null;
  }

  if (onlyNarration) {
    return first((s) => extractNarration(s.text)) ??
        first((s) => extractNarration(s.reasoning)) ??
        first((s) => lastSentence(s.reasoning)) ??
        first((s) => lastSentence(s.text));
  }
  return first((s) => lastSentence(s.reasoning)) ?? first((s) => lastSentence(s.text));
}

/// The tail of [text]: what the model said last, whole.
///
/// A thought usually ends on a short hinge — 「让我查一下。」「先看看屏幕状态。」
/// — which says nothing on its own. So the last sentence is joined with the one
/// before it until the line carries at least [minChars] characters (or there is
/// nothing left to join). The result is what the person reads: the most recent
/// *complete* thought, not the last few characters of it.
String? lastSentence(String text, {int minChars = 24}) {
  final clean = text.replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F\x7F]'), ' ').trimRight();
  if (clean.isEmpty) return null;
  final sentences = [
    for (final m in RegExp(r'[^\n。．!?！？]*[。．!?！？]').allMatches(clean))
      if (m.group(0)!.trim().isNotEmpty) m.group(0)!.trim(),
  ];
  // No terminator yet (still streaming): the last line is all there is.
  if (sentences.isEmpty) {
    final line = clean.split('\n').last.trim();
    return line.isEmpty ? null : line;
  }
  var joined = sentences.last;
  for (var i = sentences.length - 2; i >= 0; i--) {
    if (joined.runes.length >= minChars) break;
    joined = '${sentences[i]}$joined';
  }
  return joined.isEmpty ? null : joined;
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
  // Only the published line: watching the transcript here would create a
  // second ChatController for a conversation nobody has open (it would connect,
  // sync and hold the keep-alive), and the pet must not do that.
  final raw = publishedThought(target.sessionId);
  final line = raw == null
      ? null
      : (prefs.thoughtOnlyNarration ? (extractNarration(raw) ?? raw) : raw);
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

// -----------------------------------------------------------------------------
// 会话页写、宠物读

/// The newest thought line, per conversation, pushed by the chat screen while it
/// is on screen (see [publishThought]).
///
/// 不变量: the pet overlay outlives the chat screen (the app may be in the
/// background for an hour), and `chatProvider` is autoDispose with a one-minute
/// tail. Reading the transcript from the pet therefore only works while someone
/// watches it — the pet must be fed instead. This map is that feed.
final _published = <String, String>{};

/// Records what [sessionId] is thinking now; null clears it. Called by the chat
/// screen on every rebuild while a turn runs.
void publishThought(String sessionId, String? line) {
  final next = line?.trim();
  if (next == null || next.isEmpty) {
    _published.remove(sessionId);
  } else {
    _published[sessionId] = next;
  }
}

/// The line last published for [sessionId], if any.
String? publishedThought(String sessionId) => _published[sessionId];

/// Forgets a conversation (its turn ended): 「看思考」 says there is nothing.
void clearThought(String sessionId) => _published.remove(sessionId);

/// Keeps [_published] fed while [sessionId]'s screen is alive: watching it is
/// what starts the feed. The chat screen watches it once; everything else reads
/// the map, which survives the screen (and its autoDispose transcript).
final petThoughtFeedProvider = Provider.family<void, String>((ref, sessionId) {
  final prefs = ref.watch(petPrefsProvider);
  ref.listen<ChatState>(chatProvider(sessionId), (previous, next) {
    if (!next.running) {
      clearThought(sessionId);
      return;
    }
    publishThought(
      sessionId,
      petThoughtFrom(petThoughtSteps(next), onlyNarration: prefs.thoughtOnlyNarration),
    );
  }, fireImmediately: true);
  ref.onDispose(() {
    // The screen is gone: nothing more is published, but what was stays for the
    // pet (a turn may still be running while the app sits in the background).
  });
});

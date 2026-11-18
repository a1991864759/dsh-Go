import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_state.dart';

/// Which part of the chat screen a switch controls, and so which group it
/// appears under in 设置 → 界面 → 自定义界面.
enum ChatUiGroup {
  composer(zh: '输入区', en: 'Composer'),
  header(zh: '顶栏', en: 'Header'),
  messages(zh: '消息区', en: 'Messages'),
  empty(zh: '新对话页', en: 'Start page');

  const ChatUiGroup({required this.zh, required this.en});

  final String zh;
  final String en;

  String label(String locale) => locale.startsWith('en') ? en : zh;
}

/// Every chat-screen control the user can hide. The id is the enum name, which
/// is what `hidden_ui_parts` stores, so renaming an entry resets that switch.
///
/// Labels live here instead of the l10n parts on purpose: this file is meant to
/// be dropped onto a fresh upstream tag, and an l10n change would pull the
/// generated `lib/l10n/gen/**` into the diff (the most conflict-prone files).
enum ChatUiPart {
  // Composer (the input deck and what floats on it).
  activityStrip(ChatUiGroup.composer, zh: '活动条（生成中）', en: 'Activity strip', hiddenByDefault: true),
  permissionPill(ChatUiGroup.composer, zh: '完全权限胶囊', en: 'Permission capsule', hiddenByDefault: true),
  autoApprovePill(ChatUiGroup.composer, zh: '自动允许胶囊', en: 'Auto-approve capsule'),
  generateCapsule(ChatUiGroup.composer, zh: '生成模式胶囊', en: 'Generate capsule'),
  modelPill(ChatUiGroup.composer, zh: '输入框模型胶囊', en: 'Model capsule (composer)'),
  contextRing(ChatUiGroup.composer, zh: '上下文环', en: 'Context ring'),
  attachButton(ChatUiGroup.composer, zh: '附件键', en: 'Attach button'),
  voiceButton(ChatUiGroup.composer, zh: '语音键', en: 'Voice button'),
  todoPill(ChatUiGroup.composer, zh: '待办条', en: 'Todo bar'),
  goalPill(ChatUiGroup.composer, zh: '目标条', en: 'Goal bar'),

  // Header.
  headerTitle(ChatUiGroup.header, zh: '标题胶囊', en: 'Title capsule'),
  headerClock(ChatUiGroup.header, zh: '定时任务钟', en: 'Schedule clock'),
  headerAgents(ChatUiGroup.header, zh: '子代理胶囊', en: 'Agents capsule'),
  headerModel(ChatUiGroup.header, zh: '顶栏模型胶囊', en: 'Model capsule (header)'),
  headerNewChat(ChatUiGroup.header, zh: '新对话键', en: 'New chat button'),

  // Messages.
  reasoningDetails(ChatUiGroup.messages, zh: '思考过程', en: 'Reasoning details'),
  toolRows(ChatUiGroup.messages, zh: '工具调用行', en: 'Tool rows'),
  turnFooter(ChatUiGroup.messages, zh: '回合脚注', en: 'Turn footer'),
  tokenCount(ChatUiGroup.messages, zh: '脚注 token 数', en: 'Token count'),
  whaleTail(ChatUiGroup.messages, zh: '鲸尾动画', en: 'Whale tail'),

  // Start page.
  emptySuggestions(ChatUiGroup.empty, zh: '建议卡', en: 'Suggestion cards');

  const ChatUiPart(this.group, {required this.zh, required this.en, this.hiddenByDefault = false});

  final ChatUiGroup group;
  final String zh;
  final String en;

  /// Off until the user turns it on. Only the two that sit in the middle of a
  /// running conversation start hidden.
  final bool hiddenByDefault;

  String get id => name;

  String label(String locale) => locale.startsWith('en') ? en : zh;
}

/// Parts hidden when the user has never saved a choice (settings_state writes
/// the whole set on the first toggle, even when that leaves it empty).
Set<String> get defaultHiddenUiParts => {
  for (final part in ChatUiPart.values)
    if (part.hiddenByDefault) part.id,
};

/// Whether [part] is hidden right now.
final chatUiHiddenProvider = Provider.family<bool, ChatUiPart>((ref, part) {
  final settings = ref.watch(settingsProvider);
  if (settings.hiddenUiParts.contains(part.id)) return true;
  return !settings.loaded && part.hiddenByDefault;
});

/// Shorthand for widgets that only need a bool.
bool chatUiHidden(WidgetRef ref, ChatUiPart part) => ref.watch(chatUiHiddenProvider(part));

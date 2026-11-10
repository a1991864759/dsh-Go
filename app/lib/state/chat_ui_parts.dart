// 对话页上可以逐个开关的控件（设置 → 自定义界面）。
//
// 一个开关 = [ChatUiPart] 的一个值。关掉 = 从界面上整个消失，重新打开就
// 原样回来；默认值写在枚举上（活动条和完全权限胶囊默认关闭）。
//
// 有 [ChatUiPart.wire] 的项与 ui.json 的 `hide` 互通：ui.json 藏了它，
// 这里的开关也显示为关；这里的开关关了，ui.json 那一项就无从显示。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../ui_config/ui_config_model.dart' show UiHideItem;
import '../ui_config/ui_config_state.dart' show uiHiddenProvider;
import 'settings_state.dart';

/// 设置页里的分组：输入区上方与输入条、顶栏、消息区、新对话页。
enum ChatUiGroup {
  composer,
  header,
  messages,
  empty;

  String get label => switch (this) {
    ChatUiGroup.composer => appL10n.uiGroupComposer,
    ChatUiGroup.header => appL10n.uiGroupHeader,
    ChatUiGroup.messages => appL10n.uiGroupMessages,
    ChatUiGroup.empty => appL10n.uiGroupEmpty,
  };
}

/// 对话页上的一个可开关控件。
enum ChatUiPart {
  // ── 输入区：上方胶囊行、输入条内部 ──
  activityStrip(ChatUiGroup.composer, hiddenByDefault: true, wire: UiHideItem.activityStrip),
  permissionPill(ChatUiGroup.composer, hiddenByDefault: true),
  autoApprovePill(ChatUiGroup.composer),
  terminalPill(ChatUiGroup.composer, wire: UiHideItem.rootPill),
  generateCapsule(ChatUiGroup.composer),
  quickCapsules(ChatUiGroup.composer),
  pluginCapsule(ChatUiGroup.composer, wire: UiHideItem.pluginCapsule),
  todoPill(ChatUiGroup.composer, wire: UiHideItem.todoPill),
  goalPill(ChatUiGroup.composer, wire: UiHideItem.goalBar),
  modelPill(ChatUiGroup.composer),
  contextRing(ChatUiGroup.composer),
  attachButton(ChatUiGroup.composer),
  voiceButton(ChatUiGroup.composer),

  // ── 顶栏 ──
  headerTitle(ChatUiGroup.header),
  headerClock(ChatUiGroup.header),
  headerAgents(ChatUiGroup.header),
  headerModel(ChatUiGroup.header),
  headerNewChat(ChatUiGroup.header),

  // ── 消息区 ──
  reasoningDetails(ChatUiGroup.messages, wire: UiHideItem.reasoningDetails),
  toolRows(ChatUiGroup.messages),
  turnFooter(ChatUiGroup.messages, wire: UiHideItem.turnFooter),
  tokenCount(ChatUiGroup.messages, wire: UiHideItem.tokenCount),
  whaleTail(ChatUiGroup.messages, wire: UiHideItem.whaleTail),

  // ── 新对话页 ──
  emptySuggestions(ChatUiGroup.empty);

  const ChatUiPart(this.group, {this.hiddenByDefault = false, this.wire});

  final ChatUiGroup group;

  /// 新装（或还没存过这一项）时的状态。
  final bool hiddenByDefault;

  /// 同一个控件在 ui.json `hide` 里的名字（null：ui.json 管不到它）。
  final UiHideItem? wire;

  /// 存进 SharedPreferences 的名字。
  String get id => name;

  String get label => switch (this) {
    ChatUiPart.activityStrip => appL10n.uiPartActivityStrip,
    ChatUiPart.permissionPill => appL10n.uiPartPermissionPill,
    ChatUiPart.autoApprovePill => appL10n.uiPartAutoApprovePill,
    ChatUiPart.terminalPill => appL10n.uiPartTerminalPill,
    ChatUiPart.generateCapsule => appL10n.uiPartGenerateCapsule,
    ChatUiPart.quickCapsules => appL10n.uiPartQuickCapsules,
    ChatUiPart.pluginCapsule => appL10n.uiPartPluginCapsule,
    ChatUiPart.todoPill => appL10n.uiPartTodoPill,
    ChatUiPart.goalPill => appL10n.uiPartGoalPill,
    ChatUiPart.modelPill => appL10n.uiPartModelPill,
    ChatUiPart.contextRing => appL10n.uiPartContextRing,
    ChatUiPart.attachButton => appL10n.uiPartAttachButton,
    ChatUiPart.voiceButton => appL10n.uiPartVoiceButton,
    ChatUiPart.headerTitle => appL10n.uiPartHeaderTitle,
    ChatUiPart.headerClock => appL10n.uiPartHeaderClock,
    ChatUiPart.headerAgents => appL10n.uiPartHeaderAgents,
    ChatUiPart.headerModel => appL10n.uiPartHeaderModel,
    ChatUiPart.headerNewChat => appL10n.uiPartHeaderNewChat,
    ChatUiPart.reasoningDetails => appL10n.uiPartReasoningDetails,
    ChatUiPart.toolRows => appL10n.uiPartToolRows,
    ChatUiPart.turnFooter => appL10n.uiPartTurnFooter,
    ChatUiPart.tokenCount => appL10n.uiPartTokenCount,
    ChatUiPart.whaleTail => appL10n.uiPartWhaleTail,
    ChatUiPart.emptySuggestions => appL10n.uiPartEmptySuggestions,
  };

  /// 设置页按分组列出的开关。
  static List<ChatUiPart> of(ChatUiGroup group) => [
    for (final part in values)
      if (part.group == group) part,
  ];
}

/// 默认关闭的项（新装时的初值，也是「恢复默认」的样子）。
Set<String> get defaultHiddenUiParts => {
  for (final part in ChatUiPart.values)
    if (part.hiddenByDefault) part.id,
};

/// [part] 现在藏不藏：用户开关、首次加载前的默认值、ui.json 的 `hide`，
/// 三者任一为真即藏。
final uiPartHiddenProvider = Provider.family<bool, ChatUiPart>((ref, part) {
  final hidden = ref.watch(settingsProvider.select((s) => s.hiddenUiParts));
  if (hidden.contains(part.id)) return true;
  final loaded = ref.watch(settingsProvider.select((s) => s.loaded));
  if (!loaded && part.hiddenByDefault) return true;
  final wire = part.wire;
  if (wire != null && ref.watch(uiHiddenProvider(wire))) return true;
  return false;
});

/// [part] 现在的开关状态（设置页用）：ui.json 藏了它也算关。
bool uiPartHidden(WidgetRef ref, ChatUiPart part) => ref.watch(uiPartHiddenProvider(part));

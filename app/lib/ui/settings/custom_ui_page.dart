// 设置 → 自定义界面：对话页上每一个控件一个开关。
//
// 关掉一个开关，那个控件就从界面上整个消失（不占位、不画），重新打开
// 立刻回来。默认值写在 `state/chat_ui_parts.dart` 的枚举上；活动条和
// 完全权限胶囊默认关闭。
//
// 与 ui.json 的关系：同一个控件在 ui.json 的 `hide` 里时，这里的开关也
// 显示为关，并注明由 ui.json 控制；关掉这里不会改动 ui.json。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/chat_ui_parts.dart';
import '../../state/settings_state.dart';
import '../../ui_config/ui_config_state.dart' show uiHiddenProvider;
import '../shell/page_frame.dart';
import 'settings_widgets.dart';

class CustomUiPage extends ConsumerWidget {
  const CustomUiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AppPage.list(
      title: l10n.uiCustomTitle,
      children: [
        SettingsSection(
          children: [
            SettingsTile(
              title: l10n.uiCustomRestore,
              subtitle: l10n.uiCustomIntro,
              onTap: () => unawaited(ref.read(settingsProvider.notifier).setHiddenUiParts(defaultHiddenUiParts)),
            ),
          ],
        ),
        for (final group in ChatUiGroup.values)
          SettingsSection(
            title: group.label,
            children: [
              for (final part in ChatUiPart.of(group)) _PartSwitch(part: part),
            ],
          ),
      ],
    );
  }
}

/// 一个控件的开关。ui.json 也藏了它时，开关显示为关并注明来源。
class _PartSwitch extends ConsumerWidget {
  const _PartSwitch({required this.part});

  final ChatUiPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final wireHidden = switch (part.wire) {
      final wire? => ref.watch(uiHiddenProvider(wire)),
      null => false,
    };
    final shown = !settings.hiddenUiParts.contains(part.id) &&
        !wireHidden &&
        !(part.hiddenByDefault && !settings.loaded);
    return SettingsSwitchTile(
      title: part.label,
      subtitle: wireHidden ? l10n.uiCustomFromUiJson : null,
      value: shown,
      onChanged: (on) => unawaited(ref.read(settingsProvider.notifier).setUiPartHidden(part.id, !on)),
    );
  }
}

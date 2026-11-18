import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/chat_ui_parts.dart';
import '../../state/settings_state.dart';
import '../shell/page_frame.dart';
import '../theme/app_icons.dart';
import 'settings_widgets.dart';

/// 设置 → 界面 → 自定义界面: one switch per chat-screen control, grouped the
/// way the chat is laid out. Values live in `hidden_ui_parts`; the activity
/// strip and the permission capsule start hidden.
class CustomUiPage extends ConsumerWidget {
  const CustomUiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final en = locale.startsWith('en');
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    bool visible(ChatUiPart part) =>
        !settings.hiddenUiParts.contains(part.id) && (settings.loaded || !part.hiddenByDefault);
    return AppPage.list(
      title: en ? 'Customize interface' : '自定义界面',
      subtitle: Text(
        en
            ? 'Hide any control on the chat screen. Changes apply immediately.'
            : '对话界面上的控件，开就是显示、关就是隐藏，改完立刻生效。',
      ),
      children: [
        SettingsSection(
          children: [
            SettingsTile(
              icon: AppIcons.refresh,
              title: en ? 'Restore defaults' : '恢复默认',
              subtitle: en
                  ? 'Activity strip and permission capsule hidden'
                  : '活动条与完全权限胶囊隐藏，其余全部显示',
              onTap: () => unawaited(controller.resetHiddenUiParts()),
            ),
          ],
        ),
        for (final group in ChatUiGroup.values)
          if (ChatUiPart.values.any((p) => p.group == group))
            SettingsSection(
              title: group.label(locale),
              children: [
                for (final part in ChatUiPart.values.where((p) => p.group == group))
                  SettingsSwitchTile(
                    title: part.label(locale),
                    subtitle: part.hiddenByDefault ? (en ? 'Hidden by default' : '默认隐藏') : null,
                    value: visible(part),
                    onChanged: (shown) => unawaited(controller.setUiPartHidden(part.id, !shown)),
                  ),
              ],
            ),
      ],
    );
  }
}
